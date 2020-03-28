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

def _convenience_for_github_http_archive(kwargs):
    # Takes care of stripping root directory in github archives
    ## strip_prefix = "rules_cc-{}".format(rules_cc),
    ## urls = ["https://github.com/bazelbuild/rules_cc/archive/{}.zip".format(rules_cc)],
    for url in kwargs.get("urls", []):
        p = url.split("/")
        if len(p) == 7 and [p[2], p[5]] == ["github.com", "archive"] and p[6].endswith(".zip"):
            repo, zipped = p[4], p[6]
            strip = "{}-{}".format(repo, zipped.replace(".zip", ""))
            kwargs.update(strip_prefix = strip)
            break
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

    kwargs = _convenience_for_github_http_archive(kwargs)

    return impl(**kwargs)

def http_archive(**kwargs):
    name = _named(kwargs)
    if "sha256" in kwargs:
        return _http_archive(**kwargs)

    # Fields that must be here
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
        then_pop = [
            "upgrades_slug",
            "upgrade_constraint",
            "upgrade_constraint_url_contains",
        ],
        fail_if_missing_any_of = [
            "urls",
        ],
        cache_key_from = [
            "urls",
            "type",
            "upgrades_slug",
            "upgrade_constraint",
            "upgrade_constraint_url_contains",
        ],
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
