load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", _git_repository = "git_repository")

_LOCKER = " Please run `./bazel lock` first."

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
        fail("Unlocked dependency {!r}.".format(name) + _LOCKER)
    kind = lock.get("kind")
    if kind != "http_archive":
        fail("Dependency {!r} is locked as {!r}.".format(name, kind) + _LOCKER)
    sha256 = lock.get("sha256")
    if type(sha256) != type("") or len(sha256) != 64:
        fail("Bad locked sha256 for {!r}.".format(name) + _LOCKER)
    url = pin_url.replace("<pin>", pin)
    kwargs.update(sha256 = sha256, url = url)
    return _http_archive(**kwargs)

def git_repository(**kwargs):
    # lockfile checks
    locked = kwargs.pop("locked", None)
    if locked == None:
        fail(msg = "Field is required", attr = "locked")

    # git_repository checks
    name = kwargs.get("name")
    if name == None:
        fail(msg = "Field is required", attr = "name")
    if "commit" in kwargs:
        fail(msg = "Field must not be present", attr = "commit")
    tag = kwargs.pop("tag", None)
    branch = kwargs.pop("branch", None)
    if tag != None and branch != None:
        fail("Fields tag and branch cannot both be set")
    if tag != None:
        pin = "tag:" + tag
    if branch != None:
        pin = "branch:" + branch

    _deeper_lockfile_checks(locked)

    lock = locked["targets"].get(name)
    if lock == None:
        fail("Unlocked dependency {!r}.".format(name) + _LOCKER)
    kind = lock.get("kind")
    if kind != "git_repository":
        fail("Dependency {!r} is locked as {!r}.".format(name, kind) + _LOCKER)
    pinned = lock["pinned"].get(pin)
    if pinned == None:
        fail("Unlocked dependency {!r}.".format(name) + _LOCKER)
    kwargs.update(pinned)
    return _git_repository(**kwargs)
