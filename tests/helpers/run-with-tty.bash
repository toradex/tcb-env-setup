#!/usr/bin/env bash

set -euo pipefail

shell_under_test=${1?shell under test is required}
driver=${2?driver path is required}

if ! command -v script >/dev/null 2>&1; then
    echo "Error: required program not found: script" >&2
    exit 127
fi

printf -v cmd '%q -c %q' "${shell_under_test}" ". '${driver}'"
printf '%s' "${TCB_TEST_STDIN:-}" | script -qec "${cmd}" /dev/null
