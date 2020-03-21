# bazel_upgrade

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

## Examples

See:
* [http_archive](./example_http_archive_bare/WORKSPACE) example
	* compared to [bare version](./example_http_archive_locked/WORKSPACE)
* [git_repository](./example_git_repository_bare/WORKSPACE) example
	* compared to [bare version](./example_git_repository_locked/WORKSPACE)

## Ideas for the future

* First class support by creating a `bazel upgrade` or similar which would write to a versionable lockfile.
