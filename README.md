# [bazel_lock](https://github.com/fenollp/bazel_lock)

Lockfile & deps upgrader for [Bazel](https://bazel.build)

## Quick setup

Create the lockfile at the root of your workspace.
```shell
touch LOCKFILE.bzl
```

Replace your loading of `http_archive` or `git_repository`.
Remove all their `sha256` or `commit` fields: they will be read from the lockfile.
```python
load("@bazel_lock//rules:locked.bzl", "http_archive", "git_repository")
load("//:LOCKFILE.bzl", "locked")

http_archive(
    name = "...",
    locked = locked,
    url = "...",
)

git_repository(
    name = "...",
    locked = locked,
    remote = "...",
    tag = "...",
)
```

Lock your dependencies:
```shell
./bazel-lock //...  # or a specific build target

# Keep track of the lockfile
git commit -am 'Lock Bazel dependencies'
```
Repeat this last action only when adding, removing or upgrading dependencies.

## Examples

* [http_archive](./example_http_archive_bare/WORKSPACE) example
    * compared to [bare version](./example_http_archive_locked/WORKSPACE)
* [git_repository](./example_git_repository_bare/WORKSPACE) example
	* compared to [bare version](./example_git_repository_locked/WORKSPACE)

GitHub-friendly [dependency constraints](https://python-semanticversion.readthedocs.io/en/latest/reference.html#semantic_version.SimpleSpec):
[Example WORKSPACE](./example_http_archive_locked_constrained/WORKSPACE)
```python
http_archive(
    name = "bazel_skylib",
    locked = locked,
    type = "tar.gz",
    upgrade_constraint = "~=0.8",
    upgrades_slug = "bazelbuild/bazel-skylib",
)
```

## Note on hackyness

This project relies on WORKSPACE files being properly formatted. See [buildifier](https://github.com/bazelbuild/buildtools/blob/master/buildifier/README.md).
Indeed this is just a bunch of `grep`s and `awk`s. Ideally the locking would happen within Bazel.

To simulate parsing a Starlark WORKSPACE a Python rewrite is possible: `eval(open('WORKSPACE'))` within a `try..except`, using caught `NameError`s as bindings (with `load()` and such predefined).

## Rationale

Instead of setting `http_archive`'s' `sha256` or `git_repository`'s `commit` kwargs in your `./WORKSPACE` file this stores these values in `./LOCKFILE.bzl`.

Then when adding or upgrading dependencies (install then) run `bazel-lock`.

`bazel-lock` is similar to [`gazelle update-repos`](https://github.com/bazelbuild/bazel-gazelle) in that it writes & updates SHAs for you.

### Goals

* A lockfile system for Bazel
* A simple way to upgrade a specific dependency
* Editing lockfile only when running upgrader command (so never on `build`, `test`, `run` or `query`)
	* See https://www.rebar3.org/docs/dependencies

### Non-goals

* Solving dependency conflicts
* Solving deps of deps constraints
* A package manager and repository

## Ideas for the future

* First class support by creating a `bazel lock` or similar which would write to a versionable lockfile.
    * `bazel lock --upgrade <dependency>`
* Integrate with https://github.com/bazelbuild/bazel-gazelle#update-repos
