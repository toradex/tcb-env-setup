#!/usr/bin/env bash

set -euo pipefail

program=${1?program is required}
shift

tmp_output=$(mktemp)
cleanup() {
    rm -f "${tmp_output}"
}
trap cleanup EXIT

set +e
"${program}" "$@" </dev/null >"${tmp_output}" 2>&1
status=$?
set -e

cat "${tmp_output}"
exit "${status}"
