# [bazel_upgrade](https://github.com/fenollp/bazel_upgrade)

Lockfile & deps upgrader for [Bazel](https://bazel.build)

## Quick setup

Create the lockfile at the root of your workspace.
```shell
touch LOCKFILE.bzl
```

Replace your loading of `http_archive` or `git_repository`.
Remove all their `sha256` or `commit` fields: they will be read from the lockfile.
```python
load("@bazel_upgrade//rules:fetch.bzl", "http_archive", "git_repository")
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
./bazel-upgrade //...  # or a specific build target

# Keep track of the lockfile
git commit -am 'Lock Bazel dependencies'
```
Repeat this last action only when adding, removing or upgrading dependencies.

## Examples

* [http_archive](./example_http_archive_bare/WORKSPACE) example
	* compared to [bare version](./example_http_archive_locked/WORKSPACE)
* [git_repository](./example_git_repository_bare/WORKSPACE) example
	* compared to [bare version](./example_git_repository_locked/WORKSPACE)

## Rationale

Instead of setting `sha256` or `commit` kwargs in your `./WORKSPACE` file this stores these values in `./LOCKFILE.bzl`.

Then when adding or upgrading dependencies (install then) run `bazel-upgrade`.

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
