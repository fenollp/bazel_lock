def _foo_impl(ctx):
    pass

foo = rule(
    implementation = _foo_impl,
)
