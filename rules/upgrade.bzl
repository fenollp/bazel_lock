load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", _git_repository = "git_repository")

_LOCKER = " Please run `./bazel lock` first."

def _impl(**impld):
    impl = impld.pop("impl")
    root = impld.pop("root")
    vsn = impld.pop("vsn")
    kwargs = impld.pop("kwargs")

    locked = kwargs.pop("locked", None)
    if locked == None:
        fail(msg = "Field is required", attr = "locked")
    locked_version = locked.get("version")

    if locked_version == None:
        # Probably an "upgrade" session
        print("Bazel lockfile data is empty...")
        return impl(**kwargs)
    if locked_version != "zero":
        fail("locked: unsupported version {!r}".format(locked_version))

    # Remove fields that are not required once the lockfile is in place
    for field in impld.pop("pops", []):
        kwargs.pop(field)

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

    return _impl(
        kwargs = kwargs,
        impl = _http_archive,
        root = "http_archive " + url,
        vsn = "",
    )

def git_repository(**kwargs):
    # Fields that must not be here
    if "commit" in kwargs:
        fail(msg = "Field must not be present", attr = "commit")

    # Fields that must be here
    remote = kwargs.get("remote")
    if remote == None:
        fail(msg = "Field must be present", attr = "remote")
    tag = kwargs.get("tag")
    branch = kwargs.get("branch")
    if tag != None and branch != None:
        fail("Fields tag and branch cannot both be set")
    if tag == None and branch == None:
        fail("Field tag or branch must be set")

    vsn = "tag " + tag
    if branch != None:
        vsn = "branch " + branch
    return _impl(
        kwargs = kwargs,
        impl = _git_repository,
        root = "git_repository " + remote,
        vsn = vsn,
        pops = ["tag", "branch"],
    )
