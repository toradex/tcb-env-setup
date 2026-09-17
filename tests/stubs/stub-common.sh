#!/bin/sh

stub_log() {
    printf '%s %s\n' "${STUB_NAME}" "$*" >> "${TCB_STUB_LOG}"
}

# Dumps each argument on its own line, so tests can check argument boundaries.
stub_log_argv() {
    [ -n "${TCB_STUB_ARGV_FILE}" ] || return 0
    for _stub_arg in "$@"; do
        printf '<%s>\n' "${_stub_arg}" >> "${TCB_STUB_ARGV_FILE}"
    done
}
