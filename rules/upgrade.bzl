load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", _git_repository = "git_repository")

_locker = "./bazel lock"

def _deeper_lockfile_checks(locked):
    locked_version = locked.get("version")
    if locked_version != "zero":
        fail("locked: unsupported version {!r}".format(locked_version))
    locked_targets = locked.get("targets")
    if type(locked_targets) != type({}):
        fail("locked: targets must be a dict")

def _apply_pin(pin, url):
    return url.replace("<pin>", pin)

def http_archive(**kwargs):
    # lockfile checks
    locked = kwargs.pop("locked", None)
    if locked == None:
        fail(msg = "Field is required", attr = "locked")
    pin = kwargs.pop("pin", None)
    if pin == None:
        fail(msg = "Field is required", attr = "pin")
    pin_url = kwargs.pop("pin_url", kwargs.get("url"))

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
    url = _apply_pin(pin, pin_url)
    kwargs.update(sha256 = sha256, url = url)
    return _http_archive(**kwargs)

def git_repository(**kwargs):
    return _git_repository(**kwargs)
