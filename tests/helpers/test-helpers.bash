bats_load_library "bats-support/load.bash"
bats_load_library "bats-assert/load.bash"

TEST_HELPERS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEST_ROOT_DIR=$(cd "${TEST_HELPERS_DIR}/../.." && pwd)
TEST_FIXTURES_DIR="${TEST_ROOT_DIR}/tests/fixtures"
TEST_STUBS_DIR="${TEST_ROOT_DIR}/tests/stubs"
TCB_SCRIPT_PATH="${TEST_ROOT_DIR}/tcb-env-setup.sh"

quote_sh() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

shell_supports_completion() {
    case "${SHELL_UNDER_TEST}" in
        bash|zsh) return 0 ;;
        *) return 1 ;;
    esac
}

shell_supports_dashed_function_name() {
    case "${SHELL_UNDER_TEST}" in
        bash|zsh) return 0 ;;
        *) return 1 ;;
    esac
}

shell_supports_exported_functions() {
    case "${SHELL_UNDER_TEST}" in
        bash|zsh|ksh) return 0 ;;
        *) return 1 ;;
    esac
}

assert_direct_execution_failure_output() {
    assert_output --partial "Error: don't run"
}

assert_default_wrapper_exposed() {
    assert_output --partial "Run: torizoncore-builder -h"
}

assert_portable_wrapper_exposed() {
    assert_output --partial "Run: torizoncorebuilder -h"
}

portable_args_if_needed() {
    if shell_supports_dashed_function_name; then
        return 0
    fi

    printf '%s\n' "-P"
}

assert_completion_loaded_for_current_shell_mode() {
    if shell_supports_dashed_function_name; then
        assert_output --partial "__TCB_COMPLETION_LOADED__torizoncore-builder"
    else
        assert_output --partial "__TCB_COMPLETION_LOADED__torizoncorebuilder"
    fi
}

test_setup() {
    export PATH="${TEST_STUBS_DIR}:${PATH}"
    export TCB_TEST_ROOT="${BATS_TEST_TMPDIR}/sandbox"
    export TCB_STUB_LOG="${TCB_TEST_ROOT}/stub.log"
    export TCB_STUB_UNAME_R="${TCB_STUB_UNAME_R:-Linux}"
    export TCB_STUB_DOCKER_IMAGES_FILE="${TCB_STUB_DOCKER_IMAGES_FILE:-${TEST_FIXTURES_DIR}/local-tags-mixed.txt}"
    export TCB_STUB_DOCKER_PULL_RC="${TCB_STUB_DOCKER_PULL_RC:-0}"
    export TCB_STUB_DOCKER_COMPLETION_PRESENT="${TCB_STUB_DOCKER_COMPLETION_PRESENT:-0}"
    export TCB_STUB_DOCKER_COMPLETION_FILE="${TCB_STUB_DOCKER_COMPLETION_FILE:-${TEST_FIXTURES_DIR}/completion-script.bash}"
    export TCB_STUB_CURL_REMOTE_TAGS_FILE="${TCB_STUB_CURL_REMOTE_TAGS_FILE:-${TEST_FIXTURES_DIR}/remote-tags-default.json}"
    export TCB_STUB_CURL_COMPLETION_FILE="${TCB_STUB_CURL_COMPLETION_FILE:-${TEST_FIXTURES_DIR}/completion-script.bash}"
    export TCB_STUB_CURL_UPDATE_FILE="${TCB_STUB_CURL_UPDATE_FILE:-${TCB_SCRIPT_PATH}}"
    export TCB_STUB_CURL_UPDATE_STATUS="${TCB_STUB_CURL_UPDATE_STATUS:-200}"
    export TCB_STUB_HEAD_OUTPUT="${TCB_STUB_HEAD_OUTPUT:-ABC}"
    export TCB_STUB_OD_OUTPUT="${TCB_STUB_OD_OUTPUT:- 424242}"

    mkdir -p "${TCB_TEST_ROOT}"
    : > "${TCB_STUB_LOG}"
}

test_teardown() {
    unset TCB_NO_PULL
    unset TCB_COMMAND
    unset TCB_COMMAND_BASE
    unset TCB_COMMAND_ARGS
    unset TCB_TEST_STDIN
    unset TCB_STUB_DOCKER_IMAGES_FILE
    unset TCB_STUB_DOCKER_PULL_RC
    unset TCB_STUB_DOCKER_COMPLETION_PRESENT
    unset TCB_STUB_DOCKER_COMPLETION_FILE
    unset TCB_STUB_CURL_REMOTE_TAGS_FILE
    unset TCB_STUB_CURL_COMPLETION_FILE
    unset TCB_STUB_CURL_UPDATE_FILE
    unset TCB_STUB_CURL_UPDATE_STATUS
    unset TCB_STUB_UNAME_R
    unset TCB_STUB_HEAD_OUTPUT
    unset TCB_STUB_OD_OUTPUT
}

append_default_post_source_body() {
    local driver=${1}

    cat >> "${driver}" <<'EOF'
tcb_test_has_function() {
    if alias "$1" >/dev/null 2>&1; then
        return 0
    fi
    if command -v typeset >/dev/null 2>&1 && typeset -f "$1" >/dev/null 2>&1; then
        return 0
    fi
    if command -v whence >/dev/null 2>&1 && whence "$1" >/dev/null 2>&1; then
        return 0
    fi
    command -v "$1" >/dev/null 2>&1
}

printf '__TCB_COMMAND_BASE__%s\n' "${TCB_COMMAND_BASE-}"
printf '__TCB_COMMAND_ARGS__%s\n' "${TCB_COMMAND_ARGS-}"
printf '__TCB_COMMAND__%s\n' "${TCB_COMMAND-}"
printf '__TCB_COMPLETION_LOADED__%s\n' "${TCB_COMPLETION_LOADED-}"
if tcb_test_has_function "torizoncore-builder"; then
    echo '__TCB_FUNCTION__torizoncore-builder'
fi
if tcb_test_has_function "torizoncorebuilder"; then
    echo '__TCB_FUNCTION__torizoncorebuilder'
fi
EOF
}

build_source_driver() {
    local driver=${1}
    local post_body=${2:-}
    shift 2

    {
        echo "set --"
        for arg in "$@"; do
            printf 'set -- "$@" %s\n' "$(quote_sh "${arg}")"
        done
        printf '. %s "$@"\n' "$(quote_sh "${TCB_SCRIPT_PATH}")"
        echo '_tcb_status=$?'
        echo 'printf "__TCB_STATUS__%s\n" "$_tcb_status"'
    } > "${driver}"

    if [ -n "${post_body}" ]; then
        printf '%s\n' "${post_body}" >> "${driver}"
    else
        append_default_post_source_body "${driver}"
    fi

    printf 'exit "$_tcb_status"\n' >> "${driver}"
}

run_source_setup() {
    local driver="${BATS_TEST_TMPDIR}/source-driver.sh"
    build_source_driver "${driver}" "" "$@"
    run bash "${TEST_HELPERS_DIR}/run-without-tty.bash" "${SHELL_UNDER_TEST}" -c ". '${driver}'"
}

run_source_setup_with_body() {
    local post_body=${1}
    shift
    local driver="${BATS_TEST_TMPDIR}/source-driver.sh"
    build_source_driver "${driver}" "${post_body}" "$@"
    run bash "${TEST_HELPERS_DIR}/run-without-tty.bash" "${SHELL_UNDER_TEST}" -c ". '${driver}'"
}

run_source_setup_tty() {
    local stdin_payload=${1}
    shift
    local driver="${BATS_TEST_TMPDIR}/source-driver.sh"
    build_source_driver "${driver}" "" "$@"

    if ! command -v script >/dev/null 2>&1; then
        skip "script utility is required for TTY tests"
    fi

    export TCB_TEST_STDIN="${stdin_payload}"
    run bash "${TEST_HELPERS_DIR}/run-with-tty.bash" "${SHELL_UNDER_TEST}" "${driver}"
}

run_direct_script() {
    local direct_script="${BATS_TEST_TMPDIR}/tcb-env-setup-direct.sh"
    sed "1s|^#!/bin/sh$|#!/usr/bin/env ${SHELL_UNDER_TEST}|" "${TCB_SCRIPT_PATH}" > "${direct_script}"
    chmod +x "${direct_script}"
    run bash "${TEST_HELPERS_DIR}/run-without-tty.bash" "${direct_script}" "$@"
}

run_logic_body() {
    local post_body=${1}
    local library_script="${BATS_TEST_TMPDIR}/tcb-env-setup-lib.sh"
    local driver="${BATS_TEST_TMPDIR}/logic-driver.sh"

    sed '$d' "${TCB_SCRIPT_PATH}" > "${library_script}"
    {
        printf '. %s\n' "$(quote_sh "${library_script}")"
        printf '%s\n' "${post_body}"
    } > "${driver}"

    run bash "${TEST_HELPERS_DIR}/run-without-tty.bash" "${SHELL_UNDER_TEST}" -c ". '${driver}'"
}
