load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")

_locker = "./bazel lock"

# def from_locked(locked):
#     if type(locked) != "dict":
#         fail(msg="from_locked(locked) requires locked to be a dict", attr="locked")
#     for name, lock in locked.items():
#         if lock.get("kind") == "http_archive":
#             print("http_archive SHA256: {}".format(kwargs.get("sha256")))
#             _http_archive(**kwargs)

def _deeper_lockfile_checks(locked):
    locked_version = locked.get("version")
    if locked_version != "zero":
        fail("locked: unsupported version {!r}".format(locked_version))
    locked_targets = locked.get("targets")
    if type(locked_targets) != type({}):
        fail("locked: targets must be a dict")

def http_archive(**kwargs):
    # lockfile checks
    locked = kwargs.pop("locked", None)
    if locked == None:
        fail(msg = "Field is required", attr = "locked")
    pin = kwargs.pop("pin", None)
    if pin == None:
        fail(msg = "Field is required", attr = "pin")

    # http_archive checks
    name = kwargs.get("name")
    if name == None:
        fail(msg = "Field is required", attr = "name")
    if "sha256" in kwargs:
        fail(msg = "Field must not be present", attr = "sha256")

    _deeper_lockfile_checks(locked)

    lock = locked["targets"].get(name)
    if lock == None:
        fail("Unlocked dependency {!r}. Please run {!r} first.".format(name, _locker))
    kind = lock.get("kind")
    if kind != "http_archive":
        fail("Dependency {!r} is locked as {!r}. Please run {!r} first.".format(name, kind, _locker))
    sha256 = lock.get("sha256")
    if type(sha256) != type("") or len(sha256) != 64:
        fail("Bad locked sha256 for {!r}. Please run {!r} first.".format(name, _locker))
    kwargs.update(sha256 = sha256)
    return _http_archive(**kwargs)
