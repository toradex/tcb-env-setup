#!/bin/sh

set -eu

SCRIPT_PATH=${1:-tcb-env-setup.sh}
status=0

shellcheck -fgcc "${SCRIPT_PATH}" || status=$?

tab_errors=$(
    LC_ALL=C awk '
        {
            line = $0
            while ((tab = index(line, "\t")) > 0) {
                column += tab
                printf "%s:%d:%d: error: tab character is not allowed\n", FILENAME, NR, column
                line = substr(line, tab + 1)
            }
            column = 0
        }
    ' "${SCRIPT_PATH}"
)

if [ -n "${tab_errors}" ]; then
    printf '%s\n' "${tab_errors}" >&2
    status=1
fi

exit "${status}"
