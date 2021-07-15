#!/usr/bin/env bash

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
    unset OPTIND
    unset source
    unset user_tag
    unset volumes
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
}

tcb_env_setup_cleanup

# Usage help message
tcb_env_setup_usage () {
    echo "Usage: source tcb-env-setup.sh [OPTIONS]"
    echo "Options:"
    echo "-a <value>              (a)uto mode." 
    echo "                        With this flag enabled the script will automatically run with no need for user input. Valid values for <value> are either remote or local." 
    echo "                        When -a remote is passed the script will automatically use the latest version of TorizonCore Builder online, with no consideration for any local versions that may exist." 
    echo "                        When -a local is passed the script will automatically use the latest version of TorizonCore Builder found locally, with no consideration to what may be online." 
    echo "                        This flag is mutually exclusive with the -t flag." 
    echo ""    
    echo "-t <version tag>        (t)ag mode."
    echo "                        With this flag enabled the script will automatically run with no need for user input. Valid values for <version tag> can be found online here: https://registry.hub.docker.com/r/torizon/torizoncore-builder/tags?page=1&ordering=last_updated." 
    echo "                        Whatever <version tag> is provided will then be pulled from online." 
    echo "                        This flag is mutually exclusive with the -a flag." 
    echo "" 
    echo "-d                      (d)isable volumes."
    echo "                        With this flag enabled the script will setup torizoncore-builder without Docker volumes."
    echo "                        Meaning some torizoncore-builder commands will require additional directories to be passed as arguments."
    echo "                        By default with this flag excluded torizoncore-builder is setup with Docker volumes."
    echo "" 
    echo "-h                      (h)elp." 
    echo "                        Prints usage information." 
}

# Parse flags
volumes=" -v /deploy "
while [[ $# -gt 0 ]]
do
    case "$1" in
        -a) source=$2;[ "$2" ]||source="empty"; shift; shift;;
        -t) user_tag="$2";[ "$2" ]||user_tag="empty"; shift; shift;;
        -d) volumes=" "; shift;;
        -h|*) tcb_env_setup_usage; tcb_env_setup_cleanup; return;;
    esac
done

if [[ $source = "empty" ]] || [[ $user_tag = "empty" ]]
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

# Get list of image tags from docker hub
remote_tags=$(curl -L -s 'https://registry.hub.docker.com/v1/repositories/torizon/torizoncore-builder/tags' | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'name'\042/){print $(i+1)}}}' | tr -d '" ' | sed -n P)
# Get list of image tags locally
local_tags=$(docker images torizon/torizoncore-builder | sed -n 's/^.*torizoncore-builder\s\+\([0-9]\+\).*$/\1/p')

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
    if docker pull torizon/torizoncore-builder:"$chosen_tag"; then
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
    if wget -q https://raw.githubusercontent.com/toradex/tcb-env-setup/master/torizoncore-builder-completion.bash 2>/dev/null; then
        source ./torizoncore-builder-completion.bash 2>/dev/null && rm -rf torizoncore-builder-completion.bash
    fi
fi

alias torizoncore-builder='docker run --rm -it'"$volumes"'-v $(pwd):/workdir -v storage:/storage --net=host -v /var/run/docker.sock:/var/run/docker.sock torizon/torizoncore-builder:'"$chosen_tag"

echo "Setup complete! TorizonCore Builder is now ready to use."
echo "********************"
echo "Important: When you run TorizonCore Builder, the tool can only access the files inside the current working directory. Files and directories outside of the current working directory, or links to files and directories outside of the current working directory, won't be visible to TorizonCore Builder. So please make sure that, when running TorizonCore Builder, all files and directories passed as parameters are within the current working directory."
echo "Your current working directory is: $(pwd)"
echo "********************"
echo "For more information, run 'torizoncore-builder -h' or go to https://developer.toradex.com/knowledge-base/torizoncore-builder-tool"


tcb_env_setup_cleanup
unset -f tcb_env_setup_cleanup 2>/dev/null
