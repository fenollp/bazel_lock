load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", _git_repository = "git_repository")

_LOCKER = " Please run `./bazel lock` first."

def _impl(impl, root, vsn, **kwargs):
    locked = kwargs.pop("locked", None)
    if locked == None:
        fail(msg = "Field is required", attr = "locked")
    locked_version = locked.get("version")
    if locked_version != "zero":
        fail("locked: unsupported version {!r}".format(locked_version))

    pinned = locked.get(root, {}).get(vsn, {})
    if len(pinned) == 0:
        fail("Unlocked dependency {!r}.".format(kwargs.get("name")) + _LOCKER)
    kwargs.update(pinned)
    return impl(**kwargs)

def http_archive(**kwargs):
    # Fields that must not be here
    if "sha256" in kwargs:
        fail(msg = "Field must not be present", attr = "sha256")

    # Fields that must be here
    url = kwargs.get("url")
    if url == None:
        fail(msg = "Field must be present", attr = "url")

    root = "http_archive " + url
    return _impl(_http_archive, root, "", **kwargs)

def git_repository(**kwargs):
    # Fields that must not be here
    if "commit" in kwargs:
        fail(msg = "Field must not be present", attr = "commit")

    # Fields that must be here
    remote = kwargs.get("remote")
    if remote == None:
        fail(msg = "Field must be present", attr = "remote")
    tag = kwargs.pop("tag", None)
    branch = kwargs.pop("branch", None)
    if tag != None and branch != None:
        fail("Fields tag and branch cannot both be set")
    if tag == None and branch == None:
        fail("Field tag or branch must be set")

    root = "git_repository " + remote
    vsn = "tag " + tag
    if branch != None:
        vsn = "branch " + branch
    return _impl(_git_repository, root, vsn, **kwargs)
