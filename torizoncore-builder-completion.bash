#!/usr/bin/env bash

TCB_COMP_ARGS_MAIN="
    -h --help
    --verbose
    --log-level
    --log-file
    -v --version
    build
    bundle
    combine
    deploy
    dt
    dto
    images
    isolate
    kernel
    ostree
    push
    splash
    union
"

TCB_COMP_ARGS_MAIN_LOGLEVEL="
    debug
    info
    warning
    error
    critical
"

TCB_COMP_ARGS_BUILD="
    --help
    --create-template
    --file
    --force
    --set
    --no-subst
"

TCB_COMP_ARGS_BUILD_SET="
    VAR=\"value\"
"

TCB_COMP_ARGS_BUNDLE="
    --help
    --bundle-directory
    --force
    --platform
    --login
    --login-to
    --dind-param
"

TCB_COMP_ARGS_BUNDLE_PLATFORM="
    linux/arm/v7
    linux/arm64
"

TCB_COMP_ARGS_COMBINE="
    --help
    --bundle-directory
    --image-name
    --image-description
    --image-licence
    --image-release-notes
"

TCB_COMP_ARGS_DEPLOY="
    --help
    --output-directory
    --remote-host
    --remote-username
    --remote-username
    --remote-password
    --remote-port
    --mdns-source
    --reboot
    --deploy-sysroot-directory
    --image-name
    --image-description
    --image-licence
    --image-release-notes
"

TCB_COMP_ARGS_DT="
    --help
    status
    checkout
    apply
"

TCB_COMP_ARGS_DT_STATUS="
    --help
"

TCB_COMP_ARGS_DT_CHECKOUT="
    --help
"

TCB_COMP_ARGS_DT_APPLY="
    --help
    --include-dir
"

TCB_COMP_ARGS_DTO="
    --help
    apply
    list
    status
    remove
    deploy
"

TCB_COMP_ARGS_DTO_APPLY="
    --help
    --include-dir
    --device-tree
    --force
"

TCB_COMP_ARGS_DTO_LIST="
    --help
    --device-tree
"

TCB_COMP_ARGS_DTO_STATUS="
    --help
"

TCB_COMP_ARGS_DTO_REMOVE="
    --help
    --all
"

TCB_COMP_ARGS_DTO_DEPLOY="
    --help
    --remote-host
    --remote-username
    --remote-password
    --remote-port
    --reboot
    --mdns-source
    --include-dir
    --force
    --device-tree
    --clear
"

TCB_COMP_ARGS_IMAGES="
    --help
    --remove-storage
    download
    serve
    unpack
"

TCB_COMP_ARGS_IMAGES_DOWNLOAD="
    --help
    --remote-host
    --remote-username
    --remote-password
    --remote-port
    --mdns-source
"

TCB_COMP_ARGS_IMAGES_UNPACK="
    --help
"

TCB_COMP_ARGS_IMAGES_SERVE="
    --help
"

TCB_COMP_ARGS_ISOLATE="
    --help
    --changes-directory
    --force
    --remote-host
    --remote-username
    --remote-password
    --remote-port
    --mdns-source
"

TCB_COMP_ARGS_KERNEL="
    --help
    build_module
    set_custom_args
    get_custom_args
    clear_custom_args
"

TCB_COMP_ARGS_KERNEL_BUILD_MODULE="
    --help
    --autoload
"

TCB_COMP_ARGS_KERNEL_SET_CUSTOM_ARGS="
    --help
"

TCB_COMP_ARGS_KERNEL_GET_CUSTOM_ARGS="
    --help
"

TCB_COMP_ARGS_KERNEL_CLEAR_CUSTOM_ARGS="
    --help
"

TCB_COMP_ARGS_OSTREE="
    --help
    serve
"

TCB_COMP_ARGS_OSTREE_SERVE="
    --help
    --ostree-repo-directory
"

TCB_COMP_ARGS_PUSH="
    --help
    --credentials
    --repo
    --hardwareid
    --canonicalize
    --no-canonicalize
    --canonicalize-only
    --force
    --verbose
"

TCB_COMP_ARGS_SPLASH="
    --help
"

TCB_COMP_ARGS_UNION="
    --help
    --changes-directory
    --subject
    --body
"

# default value to complete parameters
TCB_COMP_ARGS_DEF_PASSWORD="_TYPE_HERE_PASSWORD_"
TCB_COMP_ARGS_DEF_USERNAME="_TYPE_HERE_USERNAME_"
TCB_COMP_ARGS_DEF_REGISTRY="_TYPE_HERE_REGISTRY_"
TCB_COMP_ARGS_DEF_DIND="_TYPE_HERE_DIND_PARAM_"
TCB_COMP_ARGS_DEF_IMAGE_NAME="_TYPE_HERE_IMAGE_NAME_"
TCB_COMP_ARGS_DEF_IMAGE_DESCRIPTION="_TYPE_HERE_IMAGE_DESCRIPTION_"
TCB_COMP_ARGS_DEF_REMOTE_HOST="_TYPE_HERE_REMOTE_HOST_"
TCB_COMP_ARGS_DEF_REMOTE_USERNAME="torizon"
TCB_COMP_ARGS_DEF_REMOTE_PASSWORD="_TYPE_HERE_PASSWORD_"
TCB_COMP_ARGS_DEF_REMOTE_PORT="_TYPE_HERE_REMOTE_PORT_"
TCB_COMP_ARGS_DEF_MDNS_SOURCE="_TYPE_HERE_MDNS_SOURCE_"
TCB_COMP_ARGS_DEF_KERNEL_ARGS="ARG1=VAL1"
TCB_COMP_ARGS_DEF_HARDWAREIDS="_TYPE_HERE_HARDWARE_IDS_"
TCB_COMP_ARGS_DEF_SUBJECT="_TYPE_HERE_COMMIT_SUBJECT_"
TCB_COMP_ARGS_DEF_BODY="_TYPE_HERE_COMMIT_BODY_"
TCB_COMP_ARGS_DEF_OSTREE_REF="_TYPE_HERE_OSTREE_REF_"
TCB_COMP_ARGS_DEF_UNION_BRANCH="_TYPE_HERE_UNION_BRANCH_"

# return in $COMPREPLY a list of files and directories starting from the
# current working directory. The first parameter can be used to filter
# the output files (e.g. *.txt), and if not passed, only directories are
# returned
_torizoncore-builder_completions_helper_filter_files_and_dirs() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local filterpath="$1"

    local IFS=$'\n'
    local LASTCHAR=' '

    compopt -o nospace

    if [ -z "$filterpath" ]; then
        COMPREPLY=($(compgen -d -- ${cur}))
    else
        COMPREPLY=($(compgen -o plusdirs -f -X "!$filterpath" -- ${cur}))
    fi

    if [ ${#COMPREPLY[@]} = 1 ]; then
        [ -d "$COMPREPLY" ] && LASTCHAR=/
        COMPREPLY=$(printf %q%s "$COMPREPLY" "$LASTCHAR")
    else
        for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
            [ -d "${COMPREPLY[$i]}" ] && COMPREPLY[$i]=${COMPREPLY[$i]}/
        done
    fi
}

# return in $COMPREPLY a list of directories starting from the current
# working directory.
_torizoncore-builder_completions_helper_filter_dirs() {
    _torizoncore-builder_completions_helper_filter_files_and_dirs ""
}

# return in $COMPREPLY a list of static options passed as a parameter
# to this function, removing the list the last typed word
_torizoncore-builder_completions_helper_static_options() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local opts=$(compgen -W "$@" -- ${cur})
    COMPREPLY=(${opts/$prev/})
}

# given the current command line, return the current subcommand being processed.
# For example, 'torizoncore-builder images unpack' will return 'unpack'
_torizoncore-builder_completions_helper_find_subcmd() {
    local cmd=$1
    local opts=$2

    local cmd_found=0
    local i=1

    while [ $i -lt $((COMP_CWORD+1)) ]; do
        local word="${COMP_WORDS[i]}"
        local opt=""

        first_chars=$(echo $word | cut -c1-2)

        if [ "$word" == "$cmd" ]; then
            cmd_found=1
        elif [ "$cmd_found" == "1" -a "$first_chars" != "--" ]; then
            for opt in $opts; do
                if [ "$word" == "$opt" ]; then
                    echo $word
                    return
                fi
            done
        fi

        i=$((i + 1))
    done
}

# 'build' command
_torizoncore-builder_completions_build() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --file)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "*.y*ml"
            ;;
        --set)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_BUILD_SET"
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_BUILD"
            ;;
    esac
}

# 'bundle' command
_torizoncore-builder_completions_bundle() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev1="${COMP_WORDS[COMP_CWORD-1]}"
    local prev2="${COMP_WORDS[COMP_CWORD-2]}"
    local prev3="${COMP_WORDS[COMP_CWORD-3]}"

    case "$prev3" in
        --login-to)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_PASSWORD"
            return
            ;;
    esac

    case "$prev2" in
        --login)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_PASSWORD"
            return
            ;;
        --login-to)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_USERNAME"
            return
            ;;
    esac

    case "$prev1" in
        --bundle-directory)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --platform)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_BUNDLE_PLATFORM"
            ;;
        --login)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_USERNAME"
            ;;
        --login-to)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REGISTRY"
            ;;
        --dind-param)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_DIND"
            ;;
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_BUNDLE"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_files_and_dirs "*.y*ml"
            fi
            ;;
    esac
}

# 'combine' command
_torizoncore-builder_completions_combine() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --bundle-directory)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --image-name)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_IMAGE_NAME"
            ;;
        --image-description)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_IMAGE_DESCRIPTION"
            ;;
        --image-licence|--image-release-notes)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "*"
            ;;
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_COMBINE"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_dirs
            fi
            ;;
    esac
}

# 'deploy' command
_torizoncore-builder_completions_deploy() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --bundle-directory|--output-directory|--deploy-sysroot-directory)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --image-name)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_IMAGE_NAME"
            ;;
        --image-description)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_IMAGE_DESCRIPTION"
            ;;
        --remote-host)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_HOST"
            ;;
        --remote-username)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_USERNAME"
            ;;
        --remote-password)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PASSWORD"
            ;;
        --remote-port)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PORT"
            ;;
        --mdns-source)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_MDNS_SOURCE"
            ;;
        --image-licence|--image-release-notes)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "*"
            ;;
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEPLOY"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_OSTREE_REF"
            fi
            ;;
    esac
}

# 'dt apply' command
_torizoncore-builder_completions_dt_apply() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --include-dir)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        *.dts)
            ;;
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DT_APPLY"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_files_and_dirs "*.dts"
            fi
            ;;
    esac
}

# 'dt' command
_torizoncore-builder_completions_dt() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    local cmd=$(_torizoncore-builder_completions_helper_find_subcmd "dt" "$TCB_COMP_ARGS_DT")

    case "$cmd" in
        status)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DT_STATUS"
            ;;
        checkout)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DT_CHECKOUT"
            ;;
        apply)
            _torizoncore-builder_completions_dt_apply
            ;;
        *)
            if [ "$prev" = "dt" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DT"
            fi
            ;;
    esac
}

# 'dto apply' command
_torizoncore-builder_completions_dto_apply() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local prev2="${COMP_WORDS[COMP_CWORD-2]}"

    case "$prev" in
        --include-dir)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --device-tree)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "*.dts"
            ;;
        *.dts)
            if [ "$prev2" != "--device-tree" ]; then
                return;
            fi
            ;;&
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DTO_APPLY"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_files_and_dirs "*.dts"
            fi
            ;;
    esac
}

# 'dto list' command
_torizoncore-builder_completions_dto_list() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --device-tree)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "*.dts"
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DTO_LIST"
            ;;
    esac
}

# 'dto remove' command
_torizoncore-builder_completions_dto_remove() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        *.dtbo)
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DTO_REMOVE"
            ;;
    esac
}

# 'dto deploy' command
_torizoncore-builder_completions_dto_deploy() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local prev2="${COMP_WORDS[COMP_CWORD-2]}"

    case "$prev" in
        --include-dir)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --device-tree)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "*.dts"
            ;;
        --remote-host)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_HOST"
            ;;
        --remote-username)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_USERNAME"
            ;;
        --remote-password)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PASSWORD"
            ;;
        --remote-port)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PORT"
            ;;
        --mdns-source)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_MDNS_SOURCE"
            ;;
        *.dts)
            if [ "$prev2" != "--device-tree" ]; then
                return;
            fi
            ;;&
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DTO_DEPLOY"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_files_and_dirs "*.dts"
            fi
            ;;
    esac
}

# 'dto' command
_torizoncore-builder_completions_dto() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local cmd=$(_torizoncore-builder_completions_helper_find_subcmd "dto" "$TCB_COMP_ARGS_DTO")

    case "$cmd" in
        apply)
            _torizoncore-builder_completions_dto_apply
            ;;
        list)
            _torizoncore-builder_completions_dto_list
            ;;
        status)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DTO_STATUS"
            ;;
        remove)
            _torizoncore-builder_completions_dto_remove
            ;;
        deploy)
            _torizoncore-builder_completions_dto_deploy
            ;;
        *)
            if [ "$prev" = "dto" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DTO"
            fi
            ;;
    esac
}

# 'images unpack' command
_torizoncore-builder_completions_images_unpack() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_IMAGES_UNPACK"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_files_and_dirs "*"
            fi
            ;;
    esac
}

# 'images download' command
_torizoncore-builder_completions_images_download() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --remote-host)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_HOST"
            ;;
        --remote-username)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_USERNAME"
            ;;
        --remote-password)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PASSWORD"
            ;;
        --remote-port)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PORT"
            ;;
        --mdns-source)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_MDNS_SOURCE"
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_IMAGES_DOWNLOAD"
            ;;
    esac
}

# 'images serve' command
_torizoncore-builder_completions_images_serve() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_IMAGES_SERVE"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_dirs
            fi
            ;;
    esac
}

# 'images' command
_torizoncore-builder_completions_images() {
    local cmd=$(_torizoncore-builder_completions_helper_find_subcmd "images" "$TCB_COMP_ARGS_IMAGES")

    case "$cmd" in
        unpack)
            _torizoncore-builder_completions_images_unpack
            ;;
        download)
            _torizoncore-builder_completions_images_download
            ;;
        serve)
            _torizoncore-builder_completions_images_serve
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_IMAGES"
            ;;
    esac
}

# 'isolate' command
_torizoncore-builder_completions_isolate() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --changes-directory)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --remote-host)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_HOST"
            ;;
        --remote-username)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_USERNAME"
            ;;
        --remote-password)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PASSWORD"
            ;;
        --remote-port)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_REMOTE_PORT"
            ;;
        --mdns-source)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_MDNS_SOURCE"
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_ISOLATE"
            ;;
    esac
}

# 'kernel build_module' command
_torizoncore-builder_completions_kernel_build_module() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_KERNEL_BUILD_MODULE"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_dirs "*"
            fi
            ;;
    esac
}

# 'kernel set_custom_args' command
_torizoncore-builder_completions_kernel_set_custom_args() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        set_custom_args)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_KERNEL_SET_CUSTOM_ARGS"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_KERNEL_ARGS"
            fi
            ;;
    esac
}

# 'kernel' command
_torizoncore-builder_completions_kernel() {
    local cmd=$(_torizoncore-builder_completions_helper_find_subcmd "kernel" "$TCB_COMP_ARGS_KERNEL")

    case "$cmd" in
        build_module)
            _torizoncore-builder_completions_kernel_build_module
            ;;
        set_custom_args)
            _torizoncore-builder_completions_kernel_set_custom_args
            ;;
        get_custom_args)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_KERNEL_GET_CUSTOM_ARGS"
            ;;
        clear_custom_args)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_KERNEL_CLEAR_CUSTOM_ARGS"
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_KERNEL"
            ;;
    esac
}

# 'ostree serve' command
_torizoncore-builder_completions_ostree_serve() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --ostree-repo-directory)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_OSTREE_SERVE"
            ;;
    esac
}

# 'ostree' command
_torizoncore-builder_completions_ostree() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    local cmd=$(_torizoncore-builder_completions_helper_find_subcmd "ostree" "$TCB_COMP_ARGS_OSTREE")

    case "$cmd" in
        serve)
            _torizoncore-builder_completions_ostree_serve
            ;;
        *)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_OSTREE"
            ;;
    esac
}

# 'push' command
_torizoncore-builder_completions_push() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --credentials)
            _torizoncore-builder_completions_helper_filter_files_and_dirs "credentials.zip"
            ;;
        --repo)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --hardwareid)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_HARDWAREIDS"
            ;;
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_PUSH"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_OSTREE_REF"
            fi
            ;;
    esac
}

# 'splash' command
_torizoncore-builder_completions_splash() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_SPLASH"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_filter_files_and_dirs "*"
            fi
            ;;
    esac
}

# 'union' command
_torizoncore-builder_completions_union() {
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --changes-directory)
            _torizoncore-builder_completions_helper_filter_dirs
            ;;
        --subject)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_SUBJECT"
            ;;
        --body)
            _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_BODY"
            ;;
        *)
            if [ -n "$cur" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_UNION"
            fi
            if [ -z "$COMPREPLY" ]; then
                _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_DEF_UNION_BRANCH"
            fi
            ;;
    esac
}

# 'main' command
_torizoncore-builder_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local i=1 cmd

    # find the subcommand
    while [[ "$i" -lt "$COMP_CWORD" ]]
    do
        local s="${COMP_WORDS[i]}"
        i=$((i + 1))
        case "$s" in
            --log-level)
                if [ "$i" -eq "$COMP_CWORD" ]; then
                    _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_MAIN_LOGLEVEL"
                    return
                else
                    i=$((i + 1))
                fi
                ;;
            --log-file)
                if [ "$i" -eq "$COMP_CWORD" ]; then
                    _torizoncore-builder_completions_helper_filter_files_and_dirs "*"
                    return
                else
                    i=$((i + 1))
                fi
                ;;
            -*)
                ;;
            *)
                cmd="$s"
                break
                ;;
        esac
    done

    if [ -z "$cmd" ]; then
        _torizoncore-builder_completions_helper_static_options "$TCB_COMP_ARGS_MAIN"
        return
    fi

    case "$cmd" in
        build)
            _torizoncore-builder_completions_build
            ;;
        bundle)
            _torizoncore-builder_completions_bundle
            ;;
        combine)
            _torizoncore-builder_completions_combine
            ;;
        deploy)
            _torizoncore-builder_completions_deploy
            ;;
        dt)
            _torizoncore-builder_completions_dt
            ;;
        dto)
            _torizoncore-builder_completions_dto
            ;;
        images)
            _torizoncore-builder_completions_images
            ;;
        isolate)
            _torizoncore-builder_completions_isolate
            ;;
        kernel)
            _torizoncore-builder_completions_kernel
            ;;
        ostree)
            _torizoncore-builder_completions_ostree
            ;;
        push)
            _torizoncore-builder_completions_push
            ;;
        splash)
            _torizoncore-builder_completions_splash
            ;;
        union)
            _torizoncore-builder_completions_union
            ;;
        *)
            ;;
    esac
}

complete -o bashdefault -F _torizoncore-builder_completions torizoncore-builder
