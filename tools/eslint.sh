#!/usr/bin/env bash

set -euo pipefail # go/bash-strict-mode
# Log executed lines to console when DEBUG environment variable is set.
[[ -n "${DEBUG:-}" ]] && set -x

if [[ ! -x "${1:-}" || ! -d "${BUILD_WORKING_DIRECTORY:-}" ]]; then
  # Doesn't look like we were run from bazel.
  exec bazel run //tools:eslint -- "$@"
fi

execroot="${PWD}"
eslint="${execroot}/$1"
shift

help()
{
  # Display help
  echo "Usage: $0 [options] [dir/file.ts]"
  echo
  echo "options:"
  echo "-h|--help     Show this help."
  echo "-c|--check    Check eslint rules (default)."
  echo "-f|--fix      Run eslint to fix code style and/or format."
  echo
}

mode=check

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      help
      exit 1
      ;;
    -c|--check)
      shift
      ;;
    -f|--fix)
      mode=fix
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option $1"
      help
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

# Go to the root git directory.
cd "$(git -C "${BUILD_WORKING_DIRECTORY}" rev-parse --show-toplevel)"

if [[ $# -eq 0 ]]; then
  args=( "${PWD}" )
else
  args=( "$@" )
fi

cmd=( "${eslint}" )
case "${mode}" in
  check)
    cmd+=( --ext ".ts,.html" )
    ;;
  fix)
    cmd+=( --fix --ext .ts )
    ;;
  *)
    echo 1>&2 "Unknown mode ${mode}"
    exit 1
    ;;
esac
cmd+=( "${args[@]}" )

# The nodejs_binary shell script looks at $0.runfiles.
# Normally, $0 changes when we execute it, unless we use bash -c.
# We have to manually set NODE_PATH: https://github.com/bazelbuild/rules_nodejs/issues/3624
NODE_PATH="${execroot}/external/npm/node_modules" bash -c "source ${cmd[0]}" "$0" "${cmd[@]:1}"
