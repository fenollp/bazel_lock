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

def _maybe_set_strip_prefix_of_http_archive(kwargs):
    strip_prefix = kwargs.get("strip_prefix", None)
    if type(strip_prefix) == type(""):
        # If user manually set option, use it.
        return kwargs
    endings = [".tar.gz", ".zip"]
    for url in kwargs.get("urls", []):
        p = url.split("/")
        if type(strip_prefix) == type(True) and strip_prefix:
            # If user set option to True
            name = p[-1]
            for ending in endings:
                name = name.replace(ending, "")
            kwargs.update(strip_prefix = name)
            return kwargs
        for ending in endings:
            # If one of the URLs is a github archive link: auto set.
            if len(p) == 7 and [p[2], p[5]] == ["github.com", "archive"] and p[6].endswith(ending):
                repo, zipped = p[4], p[6]
                strip = "{}-{}".format(repo, zipped.replace(ending, ""))
                kwargs.update(strip_prefix = strip)
                return kwargs
    return kwargs

def _contains_any_of(keys, kvs):
    for key in keys:
        if key in kvs:
            return True
    return False

def _cache_key(keys, kwargs, impl):
    s = "{}".format(impl).split("%")[-1]
    for key in keys:
        value = kwargs.get(key, "")
        if key == "urls" and len(value) > 0:
            value = value[0]
        s += " {}".format(value)
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

    # http_archive: merge url & urls fields
    url = kwargs.pop("url", None)
    if url:
        kwargs.update(urls = [url] + kwargs.get("urls", []))

    if if_contains in kwargs:
        for field in then_pop:
            if field in kwargs:
                kwargs.pop(field)

    if not _contains_any_of(fail_if_missing_any_of, kwargs):
        _err(name, "is unlocked. Please run bazel-lock first.")

    kwargs = _maybe_set_strip_prefix_of_http_archive(kwargs)

    return impl(**kwargs)

def http_archive(**kwargs):
    name = _named(kwargs)
    if "sha256" in kwargs:
        return _http_archive(**kwargs)

    SPECIALS = [
        "upgrades_slug",
        "upgrade_constraint",
        "upgrade_constraint_url_contains",
    ]

    if "locked" not in kwargs:
        for special in SPECIALS:
            if special in kwargs:
                _err(name, "is missing 'locked' field")

    has_url = _nonempty_string(kwargs.get("url"))
    has_urls = len([url for url in kwargs.get("urls", []) if _nonempty_string(url)]) != 0
    has_upgrades_slug = _nonempty_string(kwargs.get("upgrades_slug"))
    if len([42 for b in [has_url, has_urls, has_upgrades_slug] if b]) != 1:
        _err(name, "requires exactly one of 'url', 'urls' or 'upgrades_slug' to be provided")

    return _impl(
        impl = _http_archive,
        name = name,
        kwargs = kwargs,
        if_contains = "urls",
        then_pop = SPECIALS,
        fail_if_missing_any_of = [
            "urls",
        ],
        cache_key_from = [
            "urls",
            "type",
        ] + SPECIALS,
    )

def git_repository(**kwargs):
    name = _named(kwargs)
    if "commit" in kwargs:
        return _git_repository(**kwargs)

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
