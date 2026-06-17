#!/bin/bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_DIR="${ROOT_DIR}/tests"
BATS_BIN="${TEST_DIR}/bats/bats-core/bin/bats"

SHELL_UNDER_TEST=${SHELL_UNDER_TEST:-bash}
export SHELL_UNDER_TEST

if ! command -v "${SHELL_UNDER_TEST}" >/dev/null 2>&1; then
    echo "Error: shell not found: ${SHELL_UNDER_TEST}" >&2
    exit 1
fi

if [ ! -x "${BATS_BIN}" ]; then
    echo "Error: bats-core is not installed. Run tests/setup.sh first." >&2
    exit 1
fi

export BATS_LIB_PATH="${TEST_DIR}/bats"

BATS_ARGS=${BATS_ARGS:---timing}
if [ "${BATS_VERBOSE:-0}" = "1" ]; then
    BATS_ARGS="${BATS_ARGS} --show-output-of-passing-tests --verbose-run"
fi

declare -a tests=()
declare -a extra_bats_args=()

mode="tests"
for arg in "$@"; do
    if [ "${arg}" = "--" ]; then
        mode="bats_args"
        continue
    fi

    if [ "${mode}" = "tests" ]; then
        tests+=("${arg}")
    else
        extra_bats_args+=("${arg}")
    fi
done

if [ "${#tests[@]}" -eq 0 ]; then
    tests=("${TEST_DIR}"/*.bats)
fi

exec "${BATS_BIN}" ${BATS_ARGS} "${extra_bats_args[@]}" "${tests[@]}"
