#!/bin/sh

_tcb_check_sourced() {
    _TCB_SOURCED=false

    if [ -n "${ZSH_EVAL_CONTEXT}" ]; then
        # zsh
        case ${ZSH_EVAL_CONTEXT} in
            *:file|*:file:*) _TCB_SOURCED=true ;;
        esac
    elif [ -n "${KSH_VERSION}" ]; then
        # ksh
        # shellcheck disable=SC2086,SC2296
        [ "$(cd "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd "$(dirname -- ${.sh.file})" && pwd -P)/$(basename -- ${.sh.file})" ] && _TCB_SOURCED=true
    elif [ -n "${BASH_VERSION}" ]; then
        # bash
        # shellcheck disable=SC3028,SC3054
        [ "$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/$(basename -- "${BASH_SOURCE[0]}")" != "$(cd "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" ] && _TCB_SOURCED=true
    else
        # All other shells: examine $0 for known shell binary filenames
        case ${0##*/} in sh|dash) _TCB_SOURCED=true;; esac
    fi

    if [ "${_TCB_SOURCED}" = "false" ]; then
        echo "Error: don't run $0, source it:"
        echo "$ . tcb-env-setup.sh"
        exit 1
    fi
}

_tcb_cleanup() {
    unset _TCB_AUTO_MODE
    unset _TCB_CHOSEN_TAG
    unset _TCB_DOCKER_EXTRA
    unset _TCB_FUNCTION_NAME
    unset _TCB_ID
    unset _TCB_IMAGENAME
    unset _TCB_LATEST_LOCAL
    unset _TCB_LATEST_REMOTE
    unset _TCB_LOCAL_TAGS
    unset _TCB_NAMESPACE
    unset _TCB_OPT_DAEMON_VOL
    unset _TCB_OPT_DEPLOY_VOL
    unset _TCB_OPT_NETWORK
    unset _TCB_OPT_PULL_NEVER
    unset _TCB_OPT_RM
    unset _TCB_OPT_SELFNAME
    unset _TCB_OPT_STORAGE_VOL
    unset _TCB_OPT_WORKDIR_VOL
    unset _TCB_COMPLETION_DISABLED
    unset _TCB_PULL_REMOTE
    unset _TCB_REMOTE_TAGS
    unset _TCB_RUN_CMD
    unset _TCB_SCRIPT_PATH
    unset _TCB_SOURCED
    unset _TCB_STORAGE
    unset _TCB_UNDER_WINDOWS
    unset _TCB_USER_TAG
}

_tcb_teardown() {
    {
        unset -f _tcb_check_dependencies
        unset -f _tcb_check_sourced
        unset -f _tcb_check_updated
        unset -f _tcb_choose_tag
        unset -f _tcb_debug
        unset -f _tcb_define_command
        unset -f _tcb_detect_platform
        unset -f _tcb_get_latest_tag
        unset -f _tcb_init_defaults
        unset -f _tcb_load_local_tags
        unset -f _tcb_load_remote_tags
        unset -f _tcb_main
        unset -f _tcb_main0
        unset -f _tcb_maybe_load_completion
        unset -f _tcb_maybe_pull_image
        unset -f _tcb_parse_args
        unset -f _tcb_print_final_messages
        unset -f _tcb_runtime_eval
        unset -f _tcb_set_script_path
        unset -f _tcb_usage
        unset -f _tcb_validate_inputs
        unset -f _tcb_validate_stdin_tty
    } 2>/dev/null
}

_tcb_debug() {
    if [ "${TCB_DEBUG}" = "1" ]; then
        echo "[DEBUG] $*"
    fi
}

_tcb_usage() {
    cat <<EOF
Usage: . tcb-env-setup.sh [OPTIONS] [-- <docker_options>]

Optional arguments:
  -a <value>: select auto mode
      With this flag enabled the script will automatically run with no need
      for user input. Valid values for <value> are either remote or local.

      When "-a remote" is passed, the script will automatically use the
      latest version of TorizonCore Builder online, with no consideration
      for any local versions that may exist.

      When "-a local" is passed the script will automatically use the latest
      version of TorizonCore Builder found locally, with no consideration to
      what may be online. This flag is mutually exclusive with the -t flag.

  -t <version tag>: select tag mode
      With this flag enabled the script will automatically run with no need
      for user input. Valid values for <version tag> can be found online:
      https://registry.hub.docker.com/r/torizon/torizoncore-builder/tags?page=1&ordering=last_updated.
      Whatever <version tag> is provided will then be pulled from online.
      This flag is mutually exclusive with the -a flag.

  -d: disable volumes
      When this flag is passed, no deployment volume will be assigned to the
      TorizonCore Builder container as done by default.

  -s: select storage directory or Docker volume
      Internal storage directory or Docker volume that TorizonCore Builder
      should use to keep its state information and image customizations.
      It must be an absolute directory or a Docker volume name. If this
      flag is not set, the "storage" Docker volume will be used.

  -n: do not enable "host" network mode.
      Under Linux the tool runs in "host" network mode by default allowing
      it to operate as a server without explicit port publishing. Under
      Windows this mode of operation is always disabled requiring port
      publishing to be set up if the tool is to act as a server. This flag
      disables the default behavior (which is relevant under Linux).

  -c: disable completion script loading
      Forcefully disables loading of the shell completion script.

  -P: use portable command name
      Export command as "torizoncorebuilder" instead of "torizoncore-builder".

  -- <docker_options>: extra options to be passed to "docker run".
       Parameters after -- are simply forwarded to the "docker run"
       invocation in the command that the script defines.

  -h: help
       Prints usage information.

COMPATIBILITY NOTE:
  This script now exports a shell function instead of defining an alias.
  If you were relying on an alias definition, please review your usage of
  this setup script.
EOF
}

_tcb_check_updated() {
    [ ! -f "$1" ] && return

    _tcb_target_url="https://raw.githubusercontent.com/toradex/tcb-env-setup/master/tcb-env-setup.sh"
    _tcb_tmp_file=$(mktemp) || return

    _tcb_status_code=$(curl -sL -o "${_tcb_tmp_file}" -w '%{http_code}' "${_tcb_target_url}")
    _tcb_remote_cksum=$(cksum "${_tcb_tmp_file}" | cut -d ' ' -f 1)
    _tcb_local_cksum=$(cksum "$1" | cut -d ' ' -f 1)
    rm -f "${_tcb_tmp_file}"

    if [ "${_tcb_status_code}" -eq 200 ] && [ "${_tcb_remote_cksum}" != "${_tcb_local_cksum}" ]; then
        cat <<EOF
WARNING: This setup script is outdated. To update it, run:
   $ wget -O tcb-env-setup.sh ${_tcb_target_url}

EOF
    fi
}

_tcb_check_dependencies() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: required program not found: curl"
        return 1
    fi

    if ! command -v docker >/dev/null 2>&1; then
        echo "Error: required program not found: docker"
        return 1
    fi

    return 0
}

_tcb_detect_platform() {
    _TCB_UNDER_WINDOWS=false
    if uname -r | grep -i "microsoft" > /dev/null; then
        _TCB_UNDER_WINDOWS=true
    fi
}

_tcb_init_defaults() {
    _TCB_STORAGE="storage"

    _TCB_RUN_CMD=${TCB_RUN_CMD:-"docker run"}
    _TCB_OPT_RM=${TCB_OPT_RM:-"--rm"}
    _TCB_OPT_PULL_NEVER=${TCB_OPT_PULL_NEVER:-"--pull=never"}
    _TCB_OPT_DEPLOY_VOL=${TCB_OPT_DEPLOY_VOL:-"-v /deploy"}
    _TCB_OPT_STORAGE_VOL=${TCB_OPT_STORAGE_VOL:-"-v ${_TCB_STORAGE}:/storage"}
    # shellcheck disable=SC2016
    _TCB_OPT_WORKDIR_VOL=${TCB_OPT_WORKDIR_VOL:-'-v "$(pwd)":/workdir'}
    _TCB_OPT_DAEMON_VOL=${TCB_OPT_DAEMON_VOL:-"-v /var/run/docker.sock:/var/run/docker.sock"}

    if [ "${_TCB_UNDER_WINDOWS}" = "true" ]; then
        _TCB_OPT_NETWORK=${TCB_OPT_NETWORK:-""}
    else
        _TCB_OPT_NETWORK=${TCB_OPT_NETWORK:-"--network=host"}
    fi

    # shellcheck disable=SC2005,SC2046
    _TCB_ID=$(echo $(head -c 3 /dev/urandom | od -An -tu4))
    _TCB_OPT_SELFNAME=${TCB_OPT_SELFNAME:-"-e TCB_CONTAINER_NAME=tcb_${_TCB_ID} --name tcb_${_TCB_ID}"}

    _TCB_NAMESPACE=${TCB_NAMESPACE:-"torizon"}
    _TCB_IMAGENAME=${TCB_IMAGENAME:-"torizoncore-builder"}
    _TCB_FUNCTION_NAME="torizoncore-builder"
    _TCB_COMPLETION_DISABLED=false
}

_tcb_parse_args() {
    OPTIND=1
    while getopts ":a:t:s:dncPh" _tcb_opt; do
        case "${_tcb_opt}" in
            a)
                _TCB_AUTO_MODE="${OPTARG}"
                ;;
            t)
                _TCB_USER_TAG="${OPTARG}"
                ;;
            s)
                _TCB_STORAGE="${OPTARG}"
                _TCB_OPT_STORAGE_VOL="-v ${_TCB_STORAGE}:/storage"
                ;;
            d)
                # TODO: Consider deprecating this switch (or describing use cases for it).
                _TCB_OPT_DEPLOY_VOL=""
                ;;
            n)
                _TCB_OPT_NETWORK=""
                ;;
            c)
                _TCB_COMPLETION_DISABLED=true
                ;;
            P)
                _TCB_FUNCTION_NAME="torizoncorebuilder"
                ;;
            h)
                _tcb_usage
                return 1
                ;;
            :)
                case "${OPTARG}" in
                    a) _TCB_AUTO_MODE="empty" ;;
                    t) _TCB_USER_TAG="empty" ;;
                    s) _TCB_STORAGE="empty" ;;
                    *)
                        _tcb_usage
                        return 1
                        ;;
                esac
                ;;
            \?)
                _tcb_usage
                return 1
                ;;
        esac
    done

    shift $((OPTIND - 1))

    _TCB_DOCKER_EXTRA="$*"
    return 0
}

_tcb_set_script_path() {
    if [ -n "${ZSH_VERSION-}" ]; then
        # shellcheck disable=SC2296
        _TCB_SCRIPT_PATH="${(%):-%x}"
    elif [ -n "$0" ]; then
        case "$0" in
            /*) _TCB_SCRIPT_PATH="$0" ;;
            *) _TCB_SCRIPT_PATH="${PWD}/$0" ;;
        esac
    else
        _TCB_SCRIPT_PATH=""
    fi
}

_tcb_validate_inputs() {
    if [ "${_TCB_AUTO_MODE}" = "empty" ] || [ "${_TCB_USER_TAG}" = "empty" ] || \
       [ "${_TCB_STORAGE}" = "empty" ]; then
        _tcb_usage
        return 1
    fi

    if [ -n "${_TCB_AUTO_MODE}" ] && [ -n "${_TCB_USER_TAG}" ]; then
        echo "Error: -a and -t are mutually exclusive. Please only use one flag at a time."
        return 1
    fi

    if [ -n "${_TCB_AUTO_MODE}" ] && [ "${_TCB_AUTO_MODE}" != "local" ] && [ "${_TCB_AUTO_MODE}" != "remote" ]; then
        echo "Error: unrecognized value ${_TCB_AUTO_MODE} for -a"
        return 1
    fi

    case "${_TCB_STORAGE}" in
        /*)
            ;;
        [a-zA-Z][a-zA-Z0-9_.-]*)
            ;;
        *)
            echo "Error: \"${_TCB_STORAGE}\" storage must be an absolute directory or a valid Docker volume name."
            return 1
            ;;
    esac

    if [ "${_TCB_UNDER_WINDOWS}" = "true" ] && [ $# -eq 0 ]; then
        echo "Warning: If you intend to use torizoncore-builder as a server (listening to ports), then you should pass extra parameters to \"docker run\" (via the -- switch)."
    fi

    return 0
}

_tcb_load_local_tags() {
    _TCB_LOCAL_TAGS=$(docker images "${_TCB_NAMESPACE}/${_TCB_IMAGENAME}" --format "{{.Tag}}" | sed -n '/^[0-9]/p')
    # shellcheck disable=SC2086,SC2116
    _TCB_LOCAL_TAGS=$(echo ${_TCB_LOCAL_TAGS})
    _TCB_LATEST_LOCAL=$(_tcb_get_latest_tag "${_TCB_LOCAL_TAGS}")
    _tcb_debug "Local tags: ${_TCB_LOCAL_TAGS}"
    _tcb_debug "Latest local tag: ${_TCB_LATEST_LOCAL}"
}

# TODO: Handle errors in this function and its calls.
_tcb_load_remote_tags() {
    [ -n "${_TCB_REMOTE_TAGS}" ] && return 0

    _TCB_REMOTE_TAGS=$(curl -L -s "https://registry.hub.docker.com/v2/namespaces/${_TCB_NAMESPACE}/repositories/${_TCB_IMAGENAME}/tags" \
                           | sed -n -e 's/\("name"\) *: *\("[^"]\+"\)/\n\1:\2\n/gp' \
                           | sed -n -e 's/"name":"\([^"]\+\)"/\1/p')
    # shellcheck disable=SC2086,SC2116
    _TCB_REMOTE_TAGS=$(echo ${_TCB_REMOTE_TAGS})
    _TCB_LATEST_REMOTE=$(_tcb_get_latest_tag "${_TCB_REMOTE_TAGS}")
    _tcb_debug "Remote tags: ${_TCB_REMOTE_TAGS}"
    _tcb_debug "Latest remote tag: ${_TCB_LATEST_REMOTE}"
}

_tcb_get_latest_tag() {
    _tcb_tag=""
    _tcb_latest=""
    _tcb_major=""
    _tcb_minor=""
    _tcb_patch=""
    _tcb_score=0
    _tcb_latest_score=-1

    # shellcheck disable=SC2116
    for _tcb_tag in $(echo "$@"); do
        case "${_tcb_tag}" in
            *[!0-9.]*|.*|*..*|*.)
                continue
                ;;
            *.*.*.*)
                continue
                ;;
            *.*.*)
                ;;
            *)
                continue
                ;;
        esac

        _tcb_major=${_tcb_tag%%.*}
        _tcb_minor=${_tcb_tag#*.}
        _tcb_minor=${_tcb_minor%%.*}
        _tcb_patch=${_tcb_tag##*.}

        [ -n "${_tcb_major}" ] || continue
        [ -n "${_tcb_minor}" ] || continue
        [ -n "${_tcb_patch}" ] || continue

        # Assumes each numeric component is in the 0-99 range.
        _tcb_score=$((_tcb_major * 10000 + _tcb_minor * 100 + _tcb_patch))
        if [ "${_tcb_score}" -gt "${_tcb_latest_score}" ]; then
            _tcb_latest=${_tcb_tag}
            _tcb_latest_score=${_tcb_score}
        fi
    done

    [ -n "${_tcb_latest}" ] || return 1
    echo "${_tcb_latest}"
}

_tcb_validate_stdin_tty() {
    if [ ! -t 0 ] && [ -z "${_TCB_AUTO_MODE}" ] && [ -z "${_TCB_USER_TAG}" ]; then
        echo "Error: stdin is not attached to a TTY." \
             "For non-interactive usage, either switch -a or -t must be passed."
        return 1
    fi

    return 0
}

_tcb_runtime_eval() {
    eval "${_TCB_RUN_CMD} $*"
}

_tcb_choose_tag() {
    _tcb_load_local_tags

    if [ -z "${_TCB_LATEST_LOCAL}" ] && [ -z "${_TCB_AUTO_MODE}" ] && [ -z "${_TCB_USER_TAG}" ]; then
        # Official tag IS NOT installed; just install it.
        echo "TorizonCore Builder is not installed. Pulling the latest version from Docker Hub..."
        _tcb_load_remote_tags
        _TCB_PULL_REMOTE=true
        _TCB_CHOSEN_TAG=${_TCB_LATEST_REMOTE}

    elif [ -n "${_TCB_LATEST_LOCAL}" ] && [ -z "${_TCB_AUTO_MODE}" ] && [ -z "${_TCB_USER_TAG}" ]; then
        # Official tag IS ALREADY installed; evaluate if an update is needed.
        _tcb_load_remote_tags
        if [ "${_TCB_LATEST_LOCAL}" = "${_TCB_LATEST_REMOTE}" ]; then
            echo "TorizonCore Builder is already up-to-date."
            _TCB_PULL_REMOTE=false
            _TCB_CHOSEN_TAG=${_TCB_LATEST_LOCAL}
        else
            echo "You have an outdated version of the tool installed (${_TCB_LATEST_LOCAL})."
            printf 'Would you like to download the latest version? [Y/n] '
            _tcb_yn=""
            read -r _tcb_yn
            case ${_tcb_yn} in
                [Yy]*|"")
                    _TCB_PULL_REMOTE=true
                    _TCB_CHOSEN_TAG=${_TCB_LATEST_REMOTE}
                    ;;
                [Nn]*)
                    _TCB_PULL_REMOTE=false
                    _TCB_CHOSEN_TAG=${_TCB_LATEST_LOCAL}
                    ;;
                *)
                    echo "Please answer yes or no."
                    return 1
                    ;;
            esac
        fi

    elif [ "${_TCB_AUTO_MODE}" = "remote" ]; then
        _tcb_load_remote_tags
        _TCB_PULL_REMOTE=true
        _TCB_CHOSEN_TAG=${_TCB_LATEST_REMOTE}

    elif [ "${_TCB_AUTO_MODE}" = "local" ]; then
        if [ -z "${_TCB_LATEST_LOCAL}" ]; then
            echo "Error: no local versions found!"
            return 1
        fi
        _TCB_PULL_REMOTE=false
        _TCB_CHOSEN_TAG=${_TCB_LATEST_LOCAL}

    elif [ -n "${_TCB_USER_TAG}" ]; then
        _TCB_PULL_REMOTE=true
        _TCB_CHOSEN_TAG=${_TCB_USER_TAG}
    fi

    _tcb_debug "Chosen tag: ${_TCB_CHOSEN_TAG:-None}"

    return 0
}

_tcb_maybe_pull_image() {
    printf 'Setting up TorizonCore Builder with version %s.\n\n' "${_TCB_CHOSEN_TAG}"

    if [ "${TCB_NO_PULL}" = "1" ] || [ "${TCB_NO_PULL}" = "true" ]; then
        # TCB_NO_PULL is user settable (both "1" and "true" are accepted).
        echo "Pulling of the image was disabled by variable TCB_NO_PULL;" \
             "make sure image is locally available before invoking TorizonCore Builder."
        return 0
    fi

    if [ "${_TCB_PULL_REMOTE}" = "true" ]; then
        printf 'Pulling TorizonCore Builder...\n'

        if [ -z "${_TCB_CHOSEN_TAG}" ]; then
            echo "Error: could not determine image tag to pull!"
            return 1
        elif docker pull "${_TCB_NAMESPACE}/${_TCB_IMAGENAME}:${_TCB_CHOSEN_TAG}"; then
            printf 'Done!\n\n'
        else
            echo "Error: could not pull TorizonCore Builder from Docker Hub!"
            return 1
        fi
    fi

    return 0
}

_tcb_maybe_load_completion() {
    if [ "${_TCB_COMPLETION_DISABLED}" = "true" ]; then
        echo "Completion script loading disabled by user."
        return
    fi

    if [ -z "${BASH_VERSION-}" ] && [ -z "${ZSH_VERSION-}" ]; then
        echo "Completion will not be available because the current shell is not supported (requires bash or zsh); " \
             "please get in contact with Toradex support if you need this feature on a different shell."
        return
    fi

    _compl_script_path="/opt/torizoncore-builder/completion-scripts/torizoncore-builder-completion.bash"
    if _tcb_runtime_eval "--entrypoint='' --workdir='/' '${_TCB_NAMESPACE}/${_TCB_IMAGENAME}:${_TCB_CHOSEN_TAG}' sh -c 'test -e ${_compl_script_path}'"; then
        echo "Loading completion script from container image."
        _tcb_tmp_file=$(mktemp) || return
        if _tcb_runtime_eval "--entrypoint='' --workdir='/' '${_TCB_NAMESPACE}/${_TCB_IMAGENAME}:${_TCB_CHOSEN_TAG}' cat '${_compl_script_path}'" \
                             > "${_tcb_tmp_file}" 2>/dev/null && [ -s "${_tcb_tmp_file}" ]; then
            # shellcheck disable=SC1090
            TCB_FUNCTION_NAME="${_TCB_FUNCTION_NAME}" . "${_tcb_tmp_file}" 2>/dev/null
        else
            echo "Failed to load completion script from container image; no completion will be available."
        fi
        rm -f "${_tcb_tmp_file}"
        return
    fi

    _tcb_load_remote_tags

    if [ "${_TCB_CHOSEN_TAG}" = "${_TCB_LATEST_REMOTE}" ]; then
        echo "Loading completion script from remote repository."
        _tcb_tmp_file=$(mktemp) || return
        if curl -sL https://raw.githubusercontent.com/toradex/tcb-env-setup/master/torizoncore-builder-completion.bash -o "${_tcb_tmp_file}" 2>/dev/null; then
            # shellcheck disable=SC1090
            TCB_FUNCTION_NAME="${_TCB_FUNCTION_NAME}" . "${_tcb_tmp_file}" 2>/dev/null
        fi
        rm -f "${_tcb_tmp_file}"
    else
        echo "Completion will not be available because selected version of the tool is not the latest official one."
    fi
}

_tcb_define_command() {
    TCB_COMMAND_BASE=${_TCB_RUN_CMD}
    TCB_COMMAND_ARGS=""
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_RM:+" ${_TCB_OPT_RM}"}"
    if [ "${TCB_NO_PULL}" = "1" ] || [ "${TCB_NO_PULL}" = "true" ]; then
        # TCB_NO_PULL is user settable (both "1" and "true" are accepted).
        TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_PULL_NEVER:+" ${_TCB_OPT_PULL_NEVER}"}"
    fi
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_DEPLOY_VOL:+" ${_TCB_OPT_DEPLOY_VOL}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_WORKDIR_VOL:+" ${_TCB_OPT_WORKDIR_VOL}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_STORAGE_VOL:+" ${_TCB_OPT_STORAGE_VOL}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_DAEMON_VOL:+" ${_TCB_OPT_DAEMON_VOL}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_NETWORK:+" ${_TCB_OPT_NETWORK}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_OPT_SELFNAME:+" ${_TCB_OPT_SELFNAME}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS}${_TCB_DOCKER_EXTRA:+" ${_TCB_DOCKER_EXTRA}"}"
    TCB_COMMAND_ARGS="${TCB_COMMAND_ARGS} ${_TCB_NAMESPACE}/${_TCB_IMAGENAME}:${_TCB_CHOSEN_TAG}"
    # shellcheck disable=SC2034
    TCB_COMMAND="${TCB_COMMAND_BASE}${TCB_COMMAND_ARGS}"

    export TCB_COMMAND_BASE TCB_COMMAND_ARGS TCB_COMMAND

    if [ "${_TCB_FUNCTION_NAME}" = "torizoncorebuilder" ]; then
        torizoncorebuilder() {
            __tcb_flags=""
            [ -t 0 ] && __tcb_flags="${__tcb_flags} -i"
            [ -t 1 ] && [ -t 2 ] && __tcb_flags="${__tcb_flags} -t"
            eval "${TCB_COMMAND_BASE}${__tcb_flags}${TCB_COMMAND_ARGS} $*"
        }
        if [ -n "${BASH_VERSION-}" ] || [ -n "${ZSH_VERSION-}" ]; then
            # shellcheck disable=SC3045
            export -f torizoncorebuilder 2>/dev/null || :
        fi
    elif [ -n "${BASH_VERSION-}" ] || [ -n "${ZSH_VERSION-}" ]; then
        eval '
        torizoncore-builder() {
            __tcb_flags=""
            [ -t 0 ] && __tcb_flags="${__tcb_flags} -i"
            [ -t 1 ] && [ -t 2 ] && __tcb_flags="${__tcb_flags} -t"
            eval "${TCB_COMMAND_BASE}${__tcb_flags}${TCB_COMMAND_ARGS} $*"
        }
        '
        # shellcheck disable=SC3045
        export -f torizoncore-builder 2>/dev/null || :
    else
        echo "Error: shell does not support function names with dashes. Re-run with -P to export torizoncorebuilder instead."
        return 1
    fi

    return 0
}

_tcb_print_final_messages() {
    _tcb_storage_desc="${_TCB_STORAGE}"

    case "${_tcb_storage_desc}" in
        [a-zA-Z][a-zA-Z0-9_.-]*)
            _tcb_storage_desc="Docker volume named '${_tcb_storage_desc}'"
            ;;
    esac

    cat <<EOF
Setup complete. TorizonCore Builder is ready to be used.

== Storage
   Internal status and image customizations will be stored in ${_tcb_storage_desc}.

== Workspace Scope
   - Only files and directories in the current working directory or below are
     visible to the tool.
   - Absolute symlinks and relative symlinks pointing outside these directories
     are also not visible/accessible to the tool.

== Help
   - Run: ${_TCB_FUNCTION_NAME} -h
   - Docs: https://developer.toradex.com/knowledge-base/torizoncore-builder-tool
EOF
    cat <<EOF

WARNING: This setup script now exposes TorizonCore Builder as a shell function,
not as an alias as older versions.

If you have existing scripts, shell startup files, or CI jobs that expect an
alias named "torizoncore-builder", review them and update the checks or
invocation logic as needed.
EOF
}

_tcb_main0() {
    _tcb_check_sourced
    _tcb_cleanup
    _tcb_detect_platform
    _tcb_init_defaults

    _tcb_parse_args "$@" || return 1
    _tcb_validate_inputs "$@" || return 1
    _tcb_validate_stdin_tty || return 1
    _tcb_check_dependencies || return 1

    if [ "${_TCB_AUTO_MODE}" != "local" ]; then
        _tcb_set_script_path
        _tcb_check_updated "${_TCB_SCRIPT_PATH}"
    fi

    _tcb_choose_tag || return 1
    _tcb_maybe_pull_image || return 1

    # TODO: Consider putting the completion script inside the container image.
    _tcb_maybe_load_completion
    _tcb_define_command || return 1
    _tcb_print_final_messages
}

_tcb_main() {
    _tcb_main0 "$@"
    _tcb_main_status=$?
    _tcb_cleanup
    _tcb_teardown
    unset -f _tcb_cleanup 2>/dev/null
    unset -f _tcb_teardown 2>/dev/null
    return "${_tcb_main_status}"
}

_tcb_main "$@"
