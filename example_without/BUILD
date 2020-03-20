sh_binary(
    name = "hello",
    srcs = select({
        "on_windows": ["hello.bat"],
        "//conditions:default": ["hello.sh"],
    }),
)

config_setting(
    name = "on_windows",
    constraint_values = ["@platforms//os:windows"],
)
