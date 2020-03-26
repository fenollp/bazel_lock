#!/bin/bash -eux

echo Running locked

pushd example_http_archive_bare >/dev/null
$BAZEL run hello
popd >/dev/null

pushd example_http_archive_locked >/dev/null
$BAZEL run hello
popd >/dev/null

pushd example_http_archive_locked_upgradable >/dev/null
$BAZEL run hello
popd >/dev/null

pushd example_git_repository_bare >/dev/null
$BAZEL run hello
popd >/dev/null

pushd example_git_repository_locked >/dev/null
$BAZEL run hello
popd >/dev/null

git --no-pager diff && [[ 0 -eq "$(git diff | wc -l)" ]]


echo Updating dependencies

pushd example_http_archive_locked >/dev/null
../bazel-lock hello
popd >/dev/null

pushd example_git_repository_locked >/dev/null
../bazel-lock hello
popd >/dev/null

git --no-pager diff && [[ 0 -eq "$(git diff | wc -l)" ]]
pushd example_http_archive_locked_upgradable >/dev/null
../bazel-lock hello
popd >/dev/null

git --no-pager diff && [[ 8 -eq "$(git diff | wc -l)" ]]


echo Running unlocked

for lockfile in example_*locked*/LOCKFILE.bzl; do echo 'locked = {}'>$lockfile; done
pushd example_http_archive_locked >/dev/null
$BAZEL run hello
popd >/dev/null

pushd example_http_archive_locked_upgradable >/dev/null
! $BAZEL run hello
popd >/dev/null

pushd example_git_repository_locked >/dev/null
$BAZEL run hello
popd >/dev/null
