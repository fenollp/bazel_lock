#!/bin/bash

set -eu
set -o pipefail
git --no-pager diff && [[ 0 -eq "$(git diff | wc -l)" ]]

echo
echo Running locked
echo

for workspace in example_*; do
	echo
	echo $workspace
	pushd $workspace >/dev/null
	$BAZEL run hello
	popd >/dev/null
done
git --no-pager diff && [[ 0 -eq "$(git diff | wc -l)" ]]


echo
echo Running unlocked
echo

for workspace in example_*locked*; do
	echo
	echo $workspace
	pushd $workspace >/dev/null

	echo 'locked = {}'>LOCKFILE.bzl

	if [[ $workspace = example_http_archive_locked_upgradable ]]; then
		! $BAZEL run hello
	else
		$BAZEL run hello
	fi

	popd >/dev/null
done


echo
echo Updating dependencies
echo

for workspace in example_*locked*; do
	echo
	echo $workspace
	pushd $workspace >/dev/null

	../bazel-lock hello

	if [[ $workspace = example_http_archive_locked_upgradable ]]; then
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		diff -q LOCKFILE.bzl upgraded_LOCKFILE.bzl
		git checkout -- LOCKFILE.bzl
	else
		git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]
	fi

	popd >/dev/null
done
