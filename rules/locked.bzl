load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", _git_repository = "git_repository")

_LOCKER = " Please run `./bazel lock` first."

def _nonempty_string(x):
    return type(x) == type("") and len(x) > 0

def _impl(impl, kwargs, to_pop):
    # Fields that must be here
    name = kwargs.get("name")
    if name == None:
        fail(msg = "Field must be present", attr = "name")

    locked = kwargs.pop("locked", None)
    if locked == None:
        fail(msg = "Field is required", attr = "locked")

    version = locked.get("version")
    if not _nonempty_string(version):
        # Most definitely called from "bazel-lock"
        for field in to_pop:
            if field in kwargs:
                kwargs.pop(field)
        print("Locking in progress... kwargs:{}".format(kwargs))
        return impl(**kwargs)
    elif version == "zero":
        # Remove fields that are not required once the lockfile is in place
        for field in to_pop:
            if field in kwargs:
                kwargs.pop(field)

        pinned = locked.get("repositories", {}).get(name, {})
        if len(pinned) == 0:
            fail("Unlocked dependency {!r}.".format(name) + _LOCKER)
        kwargs.update(pinned)
        return impl(**kwargs)
    else:
        fail("locked: unsupported version {!r}".format(version))

def http_archive(**kwargs):
    # Fields that must not be here
    if "sha256" in kwargs:
        fail(msg = "Field must not be present", attr = "sha256")

    # Fields that must be here
    url = kwargs.get("url")
    upgrades_slug = kwargs.get("upgrades_slug")
    if _nonempty_string(url) and _nonempty_string(upgrades_slug):
        fail("Fields url and upgrades_slug are mutually exclusive")
    elif _nonempty_string(url):
        pass
    elif _nonempty_string(upgrades_slug):
        pass
    else:
        fail(msg = "Field must be present", attr = "url")

    return _impl(_http_archive, kwargs, [
        "upgrades_slug",
        "upgrade_constraint",
    ])

def git_repository(**kwargs):
    # Fields that must not be here
    if "commit" in kwargs:
        fail(msg = "Field must not be present", attr = "commit")

    # Fields that must be here
    remote = kwargs.get("remote")
    if not _nonempty_string(remote):
        fail(msg = "Field must be present", attr = "remote")
    tag = kwargs.get("tag")
    branch = kwargs.get("branch")
    if _nonempty_string(tag) and _nonempty_string(branch):
        fail("Fields tag and branch cannot both be set")
    if not (_nonempty_string(tag) or _nonempty_string(branch)):
        fail("Field tag or branch must be set")

    return _impl(_git_repository, kwargs, [
        "tag",
        "branch",
    ])
