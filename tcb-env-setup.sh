#!/usr/bin/env bash

# Check to make sure script is being sourced otherwise exit
if [[ "$(basename -- "$0")" == "tcb-env-setup.sh" ]]; then
    echo "Don't run $0, source it." 
    exit 1
fi


# cleanup variables and functions used in script since script is meant to be sourced
cleanup () {
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
    unset -f print_usage
    unset -f get_latest_tag
}

cleanup

# Usage help message
print_usage () {
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
OPTIND=1
volumes=" -v /deploy "
while getopts a:t:hd flag
do
    case "${flag}" in
        a) source=${OPTARG};;
        t) user_tag=${OPTARG};;
        d) volumes=" ";;
        h|*) print_usage 
           return;;
    esac
done
# Check that only one flag is used at a time
if [[ -n $source && -n $user_tag ]]
then
    echo "-a and -t are mutually exclusive please only use one flag at a time."
    return
fi 
# Check that only valid values are passed for -a flag
if [[ -n $source && $source != "local" && $source != "remote" ]]
then
    echo "Unrecognized value $source for -a"
    return
fi

# Get list of image tags from docker hub
remote_tags=$(curl -L -s 'https://registry.hub.docker.com/v1/repositories/torizon/torizoncore-builder/tags' | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'name'\042/){print $(i+1)}}}' | tr -d '"' | sed -n P)
# Get list of image tags locally
local_tags=$(docker images torizon/torizoncore-builder | sed -n 's/^.*torizoncore-builder\s\+\([0-9]\+\).*$/\1/p')

# Determine the tag with the greatest numerical major revision
get_latest_tag () {
    latest=0
    for tag in $@
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
    echo "No local version found, pulling the latest version found online."
    pull_remote=true
    chosen_tag=$latest_remote
elif [[ -n $local_tags && -z $source && -z $user_tag ]]
then
    get_latest_tag "$local_tags"
    latest_local=$?
    read -p "Latest local version found as version: $latest_local. Check for updates online instead? [y/n] " yn
    case $yn in
        [Yy]* ) pull_remote=true
            chosen_tag=$latest_remote;;
        [Nn]* ) pull_remote=false 
            chosen_tag=$latest_local;;
        * ) echo "Please answer yes or no."
            return;;
    esac
elif [[ $source == "local" ]]
then
    get_latest_tag "$local_tags"
    latest_local=$?
    if [[ $latest_local == "0" ]]
    then
        echo "No local versions found!"
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
echo -e "Setting up torizoncore-builder with version: $chosen_tag\n"

if [[ $pull_remote == true ]]
then    
    docker pull torizon/torizoncore-builder:"$chosen_tag"
fi

alias torizoncore-builder='docker run --rm -it'"$volumes"'-v $(pwd):/workdir -v storage:/storage --net=host -v /var/run/docker.sock:/var/run/docker.sock torizon/torizoncore-builder:'"$chosen_tag"

echo -e "\nSetup complete. torizoncore-builder is now ready to use."

cleanup
unset -f cleanup
