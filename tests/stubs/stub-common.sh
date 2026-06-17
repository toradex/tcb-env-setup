#!/bin/sh

stub_log() {
    printf '%s %s\n' "${STUB_NAME}" "$*" >> "${TCB_STUB_LOG}"
}
