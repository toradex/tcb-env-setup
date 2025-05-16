#!/usr/bin/env bash

if ! command -v curl > /dev/null; then
    echo "Error: curl is not installed. Please install curl before sourcing this script."
    exit 1
fi

# Check to make sure script is being sourced otherwise exit
SOURCED=0

# zsh
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
    case $ZSH_EVAL_CONTEXT in *:file) SOURCED=1;; esac

# ksh
elif [ -n "$KSH_VERSION" ]; then
    [ "$(cd $(dirname -- "$0") && pwd -P)/$(basename -- "$0")" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && SOURCED=1

# bash
elif [ -n "$BASH_VERSION" ]; then
    (return 0 2>/dev/null) && SOURCED=1

# All other shells: examine $0 for known shell binary filenames
else
    # Detects `sh` and `dash`; add additional shell filenames as needed.
    case ${0##*/} in sh|dash) SOURCED=1;; esac
fi

# check if it was sourced
if [ "$SOURCED" = "0" ]; then
    echo "Error: don't run $0, source it."
    exit 1
fi

# cleanup variables and functions used in script since script is meant to be sourced
tcb_env_setup_cleanup () {
    unset source
    unset under_windows
    unset user_tag
    unset storage
    unset volumes
    unset network
    unset remote_tags
    unset local_tags
    unset tag
    unset latest
    unset latest_remote
    unset latest_local
    unset pull_remote
    unset chosen_tag
    unset -f tcb_env_setup_usage 2>/dev/null
    unset -f get_latest_tag 2>/dev/null
    unset -f tcb_env_setup_check_updated 2>/dev/null
}

tcb_env_setup_cleanup

# Usage help message
tcb_env_setup_usage () {
    echo "Usage: source tcb-env-setup.sh [OPTIONS] [-- <docker_options>]"
    echo ""
    echo "optional arguments:"
    echo "  -a <value>: select auto mode"
    echo "      With this flag enabled the script will automatically run with no need"
    echo "      for user input. Valid values for <value> are either remote or local."
    echo "      When \"-a remote\" is passed, the script will automatically use the"
    echo "      latest version of TorizonCore Builder online, with no consideration"
    echo "      for any local versions that may exist. When \"-a local\" is passed"
    echo "      the script will automatically use the latest version of TorizonCore"
    echo "      Builder found locally, with no consideration to what may be online."
    echo "      This flag is mutually exclusive with the -t flag."
    echo ""
    echo "  -t <version tag>: select tag mode"
    echo "      With this flag enabled the script will automatically run with no need"
    echo "      for user input. Valid values for <version tag> can be found online:"
    echo "      https://registry.hub.docker.com/r/torizon/torizoncore-builder/tags?page=1&ordering=last_updated."
    echo "      Whatever <version tag> is provided will then be pulled from online."
    echo "      This flag is mutually exclusive with the -a flag."
    echo ""
    echo "  -d: disable volumes"
    echo "      With this flag enabled the script will setup torizoncore-builder "
    echo "      without Docker volumes meaning some torizoncore-builder commands will"
    echo "      require additional directories to be passed as arguments. By default"
    echo "      with this flag excluded torizoncore-builder is setup with Docker"
    echo "      volumes."
    echo ""
    echo "  -s: select storage directory or Docker volume"
    echo "      Internal storage directory or Docker volume that TorizonCore Builder"
    echo "      should use to keep its state information and image customizations."
    echo "      It must be an absolute directory or a Docker volume name. If this"
    echo "      flag is not set, the \"storage\" Docker volume will be used."
    echo ""
    echo "  -n: do not enable \"host\" network mode."
    echo "      Under Linux the tool runs in \"host\" network mode by default allowing"
    echo "      it to operate as a server without explicit port publishing. Under"
    echo "      Windows this mode of operation is always disabled requiring port"
    echo "      publishing to be set up if the tool is to act as a server. This flag"
    echo "      disables the default behavior (which is relevant under Linux)."
    echo ""
    echo "  -- <docker_options>: extra options to be passed to \"docker run\"."
    echo "       Parameters after -- are simply forwarded to the \"docker run\""
    echo "       invocation in the alias that the script creates."
    echo ""
    echo "  -h: help"
    echo "       Prints usage information."
    echo ""
}

tcb_env_setup_check_updated() {
  # Check if md5sum on git matches the md5sum on this file.
  [ ! -f "$1" ] && return

  local target_url="https://raw.githubusercontent.com/toradex/tcb-env-setup/master/tcb-env-setup.sh"

  local status_code=$(curl -sL -o tcb-env-setup.sh.tmp -w '%{http_code}' "$target_url")
  local remote_md5sum=$(md5sum tcb-env-setup.sh.tmp | cut -d ' ' -f 1)
  local local_md5sum=$(md5sum "$1" | cut -d ' ' -f 1)
  rm tcb-env-setup.sh.tmp

  if [ "$status_code" -eq 200 -a "$remote_md5sum" != "$local_md5sum" ]; then
    echo -e "WARNING: This script is outdated. To update it, run 'wget -o tcb-env-setup.sh $target_url' \n"
  fi
}

# Are we running under Windows?
under_windows=0
if uname -r | grep -i "microsoft" > /dev/null; then
    under_windows=1
fi

# Parse flags
volumes=" -v /deploy "
storage="storage"
network=" --network=host "
if [ $under_windows = "1" ]; then
    # Do not use "host" network mode under Windows/WSL
    network=" "
fi
while [[ $# -gt 0 ]]
do
    case "$1" in
        -a) source=$2;[ "$2" ]||source="empty"; shift; shift;;
        -t) user_tag="$2";[ "$2" ]||user_tag="empty"; shift; shift;;
        -s) storage="$2";[ "$2" ]||storage="empty"; shift; shift;;
        -d) volumes=" "; shift;;
        -n) network=" "; shift;;
        --) shift; break;;
        -h|*) tcb_env_setup_usage; tcb_env_setup_cleanup; return;;
    esac
done

if [[ $source != "local" ]]
then
  if [ -z "${ZSH_VERSION-}" ]; then
    SCRIPT_PATH="$PWD/${BASH_SOURCE[0]}"
  else
    SCRIPT_PATH="${(%):-%x}"
  fi

  tcb_env_setup_check_updated $SCRIPT_PATH
fi

if [[ $source = "empty" ]] || [[ $user_tag = "empty" ]] || [[ $storage = "empty" ]]
then
    tcb_env_setup_usage
    tcb_env_setup_cleanup
    return
fi

# Check that only one flag is used at a time
if [[ -n $source && -n $user_tag ]]
then
    echo "Error: -a and -t are mutually exclusive. Please only use one flag at a time."
    tcb_env_setup_cleanup
    return
fi
# Check that only valid values are passed for -a flag
if [[ -n $source && $source != "local" && $source != "remote" ]]
then
    echo "Error: unrecognized value $source for -a"
    tcb_env_setup_cleanup
    return
fi
# Check that storage is an absolute directory or a valid Docker volume name
if [[ $storage != /* && ! $storage =~ ^[a-zA-Z][a-zA-Z0-9_.-]*$ ]]
then
    echo "Error: \"$storage\" storage must be an absolute directory or a valid Docker volume name."
    tcb_env_setup_cleanup
    return
fi
if [ $under_windows = "1" -a $# -eq 0 ]; then
    echo "Warning: If you intend to use torizoncore-builder as a server (listening to ports), then you should pass extra parameters to \"docker run\" (via the -- switch)."
fi

# Get list of image tags from docker hub
remote_tags=$(curl -L -s 'https://registry.hub.docker.com/v2/namespaces/torizon/repositories/torizoncore-builder/tags' | sed -n -e 's/\("name"\) *: *\("[^"]\{1,\}"\)/\n\1:\2\n/gp' | \
          sed -n -e 's/"name":"\([^"]\{1,\}\)"/\1/p')
# Get list of image tags locally
local_tags=$(docker images torizon/torizoncore-builder | sed -n 's/^.*torizoncore-builder[[:space:]]\{1,\}\([0-9]\{1,\}\).*$/\1/p')

# Determine the tag with the greatest numerical major revision
get_latest_tag () {
    latest=0
    for tag in $(echo $@)
    do
        if [[ $tag != *"."* ]]
        then
            if [[ $tag -gt $latest ]]
            then
                latest=$tag
            fi
        fi
    done
    return "$latest"
}

get_latest_tag "$remote_tags"
latest_remote=$?

# Figure out whether to use latest local or latest remote version of Tcore-builder based on either flags or user response
if [[ -z $local_tags  && -z $source && -z $user_tag ]]
then
    echo "TorizonCore Builder is not installed. Pulling the latest version from Docker Hub..."
    pull_remote=true
    chosen_tag=$latest_remote
elif [[ -n $local_tags && -z $source && -z $user_tag ]]
then
    get_latest_tag "$local_tags"
    latest_local=$?
    echo -n "You may have an outdated version installed. Would you like to check for updates online? [y/n] "
    read -r yn
    case $yn in
        [Yy]* ) pull_remote=true
            chosen_tag=$latest_remote;;
        [Nn]* ) pull_remote=false
            chosen_tag=$latest_local;;
        * ) echo "Please answer yes or no."
            tcb_env_setup_cleanup
            return;;
    esac
elif [[ $source == "local" ]]
then
    get_latest_tag "$local_tags"
    latest_local=$?
    if [[ $latest_local == "0" ]]
    then
        echo "Error: no local versions found!"
        tcb_env_setup_cleanup
        return
    fi
    pull_remote=false
    chosen_tag=$latest_local
elif [[ $source == "remote" ]]
then
    pull_remote=true
    chosen_tag=$latest_remote
elif [[ -n $user_tag ]]
then
    pull_remote=true
    chosen_tag=$user_tag
fi

# Sets up chosen version of Tcore-builder based on result from above
echo -e "Setting up TorizonCore Builder with version $chosen_tag.\n"

if [[ $pull_remote == true ]]
then
    echo -e "Pulling TorizonCore Builder..."
    if docker pull --platform linux/amd64 torizon/torizoncore-builder:"$chosen_tag"; then
        echo -e "Done!\n"
    else
        echo "Error: could not pull TorizonCore Builder from Docker Hub!"
        tcb_env_setup_cleanup
        return
    fi
fi

# if installing latest version, download and source the bash completion script
if [[ "$chosen_tag" == "$latest_remote" ]]
then
    if wget -q https://raw.githubusercontent.com/toradex/tcb-env-setup/master/torizoncore-builder-completion.bash -O ./torizoncore-builder-completion.bash.tmp 2>/dev/null; then
        source ./torizoncore-builder-completion.bash.tmp 2>/dev/null && rm -rf torizoncore-builder-completion.bash.tmp
    fi
fi

function tcb_dynamic_params() {
    local cont_name="tcb_$(date +%s)"
    echo "-e TCB_CONTAINER_NAME=$cont_name --name $cont_name"
}
# TODO Not compatible with ZSH
export -f tcb_dynamic_params

alias torizoncore-builder='docker run --rm -it'"$volumes"'-v "$(pwd)":/workdir -v '"$storage"':/storage -v /var/run/docker.sock:/var/run/docker.sock'"$network"'$(tcb_dynamic_params) '"$*"' torizon/torizoncore-builder:'"$chosen_tag"

echo "Setup complete! TorizonCore Builder is now ready to use."

[[ $storage =~ ^[a-zA-Z][a-zA-Z0-9_.-]*$ ]] && storage="Docker volume named '$storage'"
echo "TorizonCore Builder internal status and image customizations will be stored in $storage."

echo "********************"
echo "Important: When you run TorizonCore Builder, the tool can only access the files inside the current working directory. Files and directories outside of the current working directory, or links to files and directories outside of the current working directory, won't be visible to TorizonCore Builder. So please make sure that, when running TorizonCore Builder, all files and directories passed as parameters are within the current working directory."
echo "Your current working directory is: $(pwd)"
echo "********************"
echo "For more information, run 'torizoncore-builder -h' or go to https://developer.toradex.com/knowledge-base/torizoncore-builder-tool"


tcb_env_setup_cleanup
unset -f tcb_env_setup_cleanup 2>/dev/null
