#!/bin/bash

set -eu
set -o pipefail
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]


echo
echo Updating dependencies
echo

for workspace in example_*locked*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL run @bazel_lock//:bazel_lock -- hello

	case "$workspace" in
	example_http_archive_locked_constrained)
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		diff -q LOCKFILE.bzl upgraded_LOCKFILE.bzl
		git checkout -- LOCKFILE.bzl
		;;
	example_git_repository_locked_constrained)
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		diff -q LOCKFILE.bzl upgraded_LOCKFILE.bzl
		git checkout -- LOCKFILE.bzl
		;;
	example_http_archive_locked_HEAD)
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		git checkout -- LOCKFILE.bzl
		;;
	*)
		git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]
	esac

	popd >/dev/null
done

for workspace in example_*resolved*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	$BAZEL sync

	$BAZEL run hello

	git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]

	popd >/dev/null
done


echo
echo Running locked
echo

for workspace in example_*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null
	$BAZEL run hello
	popd >/dev/null
done
git --no-pager diff -- example_* && [[ 0 -eq "$(git diff -- example_* | wc -l)" ]]


echo
echo Running unlocked
echo

for workspace in example_*locked*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	echo 'locked = {}'>LOCKFILE.bzl

	if [[ "$workspace" = example_http_archive_locked_constrained ]] \
	|| [[ "$workspace" = example_http_archive_locked_HEAD ]] \
	|| [[ "$workspace" = example_git_repository_locked_constrained ]]
	then
		! $BAZEL run hello
	else
		$BAZEL run hello
	fi

	popd >/dev/null
done


echo
echo Bootstrapping lockfile
echo

for workspace in example_*locked*; do
	echo
	echo "$workspace"
	pushd "$workspace" >/dev/null

	# $BAZEL run @bazel_lock//:bazel_lock -- hello
	../bazel-lock hello

	case "$workspace" in
	example_http_archive_locked_constrained)
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		diff -q LOCKFILE.bzl upgraded_LOCKFILE.bzl
		git checkout -- LOCKFILE.bzl
		;;
	example_git_repository_locked_constrained)
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		diff -q LOCKFILE.bzl upgraded_LOCKFILE.bzl
		git checkout -- LOCKFILE.bzl
		;;
	example_http_archive_locked_HEAD)
		git --no-pager diff . && [[ 8 -eq "$(git diff . | wc -l)" ]]
		git checkout -- LOCKFILE.bzl
		;;
	*)
		git --no-pager diff . && [[ 0 -eq "$(git diff . | wc -l)" ]]
	esac

	popd >/dev/null
done
