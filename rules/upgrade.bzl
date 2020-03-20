load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")

def for_http_archive(**kwargs):
    print("http_archive SHA256: {}".format(kwargs.get("sha256")))
    _http_archive(**kwargs)

def _foo_impl(ctx):
    pass

foo = rule(
    implementation = _foo_impl,
)
