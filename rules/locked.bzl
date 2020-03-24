load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", _git_repository = "git_repository")

def _nonempty_string(x):
    return type(x) == type("") and len(x) > 0

def _named(kwargs):
    name = kwargs.get("name")
    if not _nonempty_string(name):
        fail(msg = "Field must be present", attr = "name")
    return name

def _err(name, msg):
    fail("Repository @{} {}".format(name, msg))

def _unrequire(name, fields, kwargs):
    for field in fields:
        if field in kwargs:
            _err(name, "requires field '{}' to not be present".format(field))

def _contains_any_of(keys, kvs):
    for key in keys:
        if key in kvs:
            return True
    return False

def _cache_key(keys, kwargs, impl):
    s = "{}".format(impl).split("%")[-1]
    for key in keys:
        s += " {}".format(kwargs.get(key, ""))
    return s

def _impl(**implkwargs):
    impl = implkwargs.pop("impl")
    name = implkwargs.pop("name")
    kwargs = implkwargs.pop("kwargs")
    if_contains = implkwargs.pop("if_contains")
    then_pop = implkwargs.pop("then_pop")
    fail_if_missing_any_of = implkwargs.pop("fail_if_missing_any_of")
    cache_key_from = implkwargs.pop("cache_key_from")

    # Fields that must be here
    if "locked" not in kwargs:
        _err(name, "requires field 'locked' to be provided")
    locked = kwargs.pop("locked")
    if type(locked) != type({}):
        _err(name, "requires field 'locked' to be a dict")

    key = _cache_key(cache_key_from, kwargs, impl)
    pinned = locked.get(key, {})
    kwargs.update(pinned)

    if if_contains in kwargs:
        for field in then_pop:
            if field in kwargs:
                kwargs.pop(field)

    if not _contains_any_of(fail_if_missing_any_of, kwargs):
        _err(name, "is unlocked. Please run bazel-lock first.")

    return impl(**kwargs)

def http_archive(**kwargs):
    name = _named(kwargs)
    _unrequire(name, ["sha256"], kwargs)

    # Fields that must be here
    has_url = _nonempty_string(kwargs.get("url"))
    has_upgrades_slug = _nonempty_string(kwargs.get("upgrades_slug"))
    if has_url and has_upgrades_slug:
        _err(name, "requires exactly one of 'url' or 'upgrades_slug' to be provided")
    elif has_url:
        pass
    elif has_upgrades_slug:
        pass
    else:
        _err(name, "is unlocked. Please run bazel-lock first.")

    return _impl(
        impl = _http_archive,
        name = name,
        kwargs = kwargs,
        if_contains = "url",
        then_pop = [
            "upgrades_slug",
            "upgrade_constraint",
        ],
        fail_if_missing_any_of = [
            "url",
        ],
        cache_key_from = [
            "url",
            "upgrades_slug",
            "upgrade_constraint",
        ],
    )

def git_repository(**kwargs):
    name = _named(kwargs)
    _unrequire(name, ["commit"], kwargs)

    # Fields that must be here
    if "remote" not in kwargs:
        _err(name, "requires string field 'remote' to be provided")
    has_tag = "tag" in kwargs
    has_branch = "branch" in kwargs
    if has_tag and has_branch or not (has_tag or has_branch):
        _err(name, "requires exactly one of 'tag' or 'branch' to be provided")

    return _impl(
        impl = _git_repository,
        name = name,
        kwargs = kwargs,
        if_contains = "commit",
        then_pop = [
            "tag",
            "branch",
        ],
        fail_if_missing_any_of = [
            "commit",
            "tag",
            "branch",
        ],
        cache_key_from = [
            "tag",
            "branch",
            "remote",
        ],
    )
