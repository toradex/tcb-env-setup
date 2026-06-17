#!/bin/bash

set -euo pipefail

CLEAN_INSTALL=${CLEAN_INSTALL:-0}

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BATS_DIR="${ROOT_DIR}/bats"

clone_bats_repo() {
    local dir="${1}/${2}"
    local repo="${2}"
    local version="${3}"

    echo "Installing ${repo} ${version}..."
    if ! git clone --depth=1 "https://github.com/bats-core/${repo}.git" -b "${version}" "${dir}" >/dev/null 2>&1; then
        echo "Error: could not clone ${repo} ${version}." >&2
        return 1
    fi
}

install_bats() {
    local repo_spec=""
    local name=""
    local version=""

    mkdir -p "${BATS_DIR}"

    if [ "${CLEAN_INSTALL}" -eq 1 ]; then
        rm -rf "${BATS_DIR}"
        mkdir -p "${BATS_DIR}"
    fi

    for repo_spec in bats-core:v1.12.0 bats-assert:v2.1.0 bats-support:v0.3.0; do
        name=${repo_spec%%:*}
        version=${repo_spec##*:}
        if [ -d "${BATS_DIR}/${name}" ]; then
            echo "Local repository for ${name} already exists; not cloning it."
            continue
        fi
        clone_bats_repo "${BATS_DIR}" "${name}" "${version}"
    done
}

if ! command -v git >/dev/null 2>&1; then
    echo "Error: required program not found: git" >&2
    exit 1
fi

install_bats
