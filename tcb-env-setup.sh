#!/usr/bin/env sh

if ! command -v curl > /dev/null; then
    echo "Error: curl is not installed. Please install curl before sourcing this script."
    exit 1
fi

# Check to make sure script is being sourced otherwise exit
SOURCED=0

# zsh
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
  case $ZSH_EVAL_CONTEXT in *:file) SOURCED=1 ;; esac

# ksh
elif [ -n "$KSH_VERSION" ]; then
  # In ksh, can use 'return' to test if sourced
  (return 0 2>/dev/null) && SOURCED=1

# bash
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && SOURCED=1

# All other shells: examine $0 for known shell binary filenames
else
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh | dash) SOURCED=1 ;; esac
fi

# check if it was sourced
if [ "$SOURCED" = "0" ]; then
  printf "Error: don't run %s, source it.\n" "$0"
  exit 1
fi

# cleanup variables and functions used in script since script is meant to be sourced
tcb_env_setup_cleanup() {
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

tcb_env_setup_usage() {
  printf "Usage: source tcb-env-setup.sh [OPTIONS] [-- <docker_options>]\n"
  printf "\n"
  printf "optional arguments:\n"
  printf "  -a <value>: select auto mode\n"
  printf "      With this flag enabled the script will automatically run with no need\n"
  printf "      for user input. Valid values for <value> are either remote or local.\n"
  printf "      When \"-a remote\" is passed, the script will automatically use the\n"
  printf "      latest version of TorizonCore Builder online, with no consideration\n"
  printf "      for any local versions that may exist. When \"-a local\" is passed\n"
  printf "      the script will automatically use the latest version of TorizonCore\n"
  printf "      Builder found locally, with no consideration to what may be online.\n"
  printf "      This flag is mutually exclusive with the -t flag.\n"
  printf "\n"
  printf "  -t <version tag>: select tag mode\n"
  printf "      With this flag enabled the script will automatically run with no need\n"
  printf "      for user input. Valid values for <version tag> can be found online:\n"
  printf "      https://registry.hub.docker.com/r/torizon/torizoncore-builder/tags?page=1&ordering=last_updated.\n"
  printf "      Whatever <version tag> is provided will then be pulled from online.\n"
  printf "      This flag is mutually exclusive with the -a flag.\n"
  printf "\n"
  printf "  -d: disable volumes\n"
  printf "      With this flag enabled the script will setup torizoncore-builder \n"
  printf "      without Docker volumes meaning some torizoncore-builder commands will\n"
  printf "      require additional directories to be passed as arguments. By default\n"
  printf "      with this flag excluded torizoncore-builder is setup with Docker\n"
  printf "      volumes.\n"
  printf "\n"
  printf "  -s: select storage directory or Docker volume\n"
  printf "      Internal storage directory or Docker volume that TorizonCore Builder\n"
  printf "      should use to keep its state information and image customizations.\n"
  printf "      It must be an absolute directory or a Docker volume name. If this\n"
  printf "      flag is not set, the \"storage\" Docker volume will be used.\n"
  printf "\n"
  printf "  -n: do not enable \"host\" network mode.\n"
  printf "      Under Linux the tool runs in \"host\" network mode by default allowing\n"
  printf "      it to operate as a server without explicit port publishing. Under\n"
  printf "      Windows this mode of operation is always disabled requiring port\n"
  printf "      publishing to be set up if the tool is to act as a server. This flag\n"
  printf "      disables the default behavior (which is relevant under Linux).\n"
  printf "\n"
  printf "  -- <docker_options>: extra options to be passed to \"docker run\".\n"
  printf "       Parameters after -- are simply forwarded to the \"docker run\"\n"
  printf "       invocation in the alias that the script creates.\n"
  printf "\n"
  printf "  -h: help\n"
  printf "       Prints usage information.\n"
  printf "\n"
}

tcb_env_setup_check_updated() {
  # Check if md5sum on git matches the md5sum on this file.
  [ ! -f "$1" ] && return

  tcb_env_setup_check_updated_target_url="https://raw.githubusercontent.com/toradex/tcb-env-setup/master/tcb-env-setup.sh"

  tcb_env_setup_check_updated_status_code=$(curl -sL -o tcb-env-setup.sh.tmp -w '%{http_code}' "$tcb_env_setup_check_updated_target_url")
  tcb_env_setup_check_updated_remote_md5sum=$(md5sum tcb-env-setup.sh.tmp | cut -d ' ' -f 1)
  tcb_env_setup_check_updated_local_md5sum=$(md5sum "$1" | cut -d ' ' -f 1)
  rm tcb-env-setup.sh.tmp

  if [ "$tcb_env_setup_check_updated_status_code" -eq 200 ] && [ "$tcb_env_setup_check_updated_remote_md5sum" != "$tcb_env_setup_check_updated_local_md5sum" ]; then
    printf "WARNING: This script is outdated. To update it, run 'wget -o tcb-env-setup.sh %s' \n" "$tcb_env_setup_check_updated_target_url"
  fi

  unset tcb_env_setup_check_updated_target_url
  unset tcb_env_setup_check_updated_status_code
  unset tcb_env_setup_check_updated_remote_md5sum
  unset tcb_env_setup_check_updated_local_md5sum
}

under_windows=0
if uname -r | grep -i "microsoft" >/dev/null; then
  under_windows=1
fi

DEFAULT_SOURCE="remote"
DEFAULT_TAG="latest"
DEFAULT_STORAGE="storage"
DEFAULT_VOLUMES=" -v /deploy "
DEFAULT_NETWORK=" --network=host "

source="$DEFAULT_SOURCE"
user_tag="$DEFAULT_TAG"
storage="$DEFAULT_STORAGE"
volumes="$DEFAULT_VOLUMES"
network="$DEFAULT_NETWORK"

if [ "$under_windows" = "1" ]; then
  # Do not use "host" network mode under Windows/WSL
  network=" "
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -a)
      if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
        source=$2
        shift
      fi
      shift
      ;;
    -t)
      if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
        user_tag=$2
        shift
      fi
      shift
      ;;
    -s)
      if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
        storage=$2
        shift
      fi
      shift
      ;;
    -d)
      volumes=true
      shift
      ;;
    -n)
      network=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -h)
      tcb_env_setup_usage
      tcb_env_setup_cleanup
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      tcb_env_setup_usage
      exit 1
      ;;
  esac
done

if [ -z "$source" ] || [ "$source" != "local" ]; then
  SCRIPT_PATH="$0"

  # zsh
  if [ -n "${ZSH_VERSION-}" ]; then
    SCRIPT_PATH="$0"
  fi

  tcb_env_setup_check_updated "$SCRIPT_PATH"
fi

if [ -z "$source" ] || [ -z "$user_tag" ] || [ -z "$storage" ]; then
  tcb_env_setup_usage
  tcb_env_setup_cleanup
  return
fi

# Check that only one flag is used at a time
if [ "$source" != "$DEFAULT_SOURCE" ] && [ "$user_tag" != "$DEFAULT_TAG" ]; then
  printf "Error: -a and -t are mutually exclusive. Please only use one flag at a time.\n"
  tcb_env_setup_cleanup
  return 1
fi

# Check that only valid values are passed for -a flag
if [ -n "$source" ] && [ "$source" != "local" ] && [ "$source" != "remote" ]; then
  printf "Error: unrecognized value %s for -a\n" "$source"
  tcb_env_setup_cleanup
  return
fi

# Check that storage is an absolute directory or a valid Docker volume name
if [ "${storage#/}" = "$storage" ] && ! expr "$storage" : '^[a-zA-Z][a-zA-Z0-9_.-]*$' >/dev/null; then
  printf "Error: \"%s\" storage must be an absolute directory or a valid Docker volume name.\n" "$storage"
  tcb_env_setup_cleanup
  return
fi

if [ "$under_windows" = "1" ] && [ $# -eq 0 ]; then
  printf "Warning: If you intend to use torizoncore-builder as a server (listening to ports), then you should pass extra parameters to \"docker run\" (via the -- switch).\n"
fi

# Get list of image tags from docker hub
raw_remote_tags=$(curl -L -s 'https://registry.hub.docker.com/v2/namespaces/torizon/repositories/torizoncore-builder/tags' | sed -n -e 's/\("name"\) *: *\("[^"]\{1,\}"\)/\n\1:\2\n/gp' |
  sed -n -e 's/"name":"\([^"]\{1,\}\)"/\1/p')
# Get list of image tags locally
remote_tags=""
for tag in $raw_remote_tags; do
  case "$tag" in
    # Removes non-alphanumeric entries (early-access, latest...)
    *[0-9]*)
      remote_tags="$remote_tags $tag"
      ;;
  esac
done
local_tags=$(docker images torizon/torizoncore-builder | sed -n 's/^.*torizoncore-builder[[:space:]]\{1,\}\([0-9]\{1,\}\).*$/\1/p')

# Determine the tag with the greatest numerical major revision
get_latest_tag() {
  get_latest_tag_latest=0
  for get_latest_tag_tag in "$@"; do
    # Contains a dot
    if ! expr "$get_latest_tag_tag" : ".*\..*" >/dev/null; then
      # Numeric comparison
      if expr "$get_latest_tag_tag" ">" "$get_latest_tag_latest" >/dev/null; then
        get_latest_tag_latest=$get_latest_tag_tag
      fi
    fi
  done
  latest=$get_latest_tag_latest
}

# Get latest remote tag
# shellcheck disable=SC2086
get_latest_tag $remote_tags
latest_remote=$latest

# Figure out whether to use latest local or latest remote version of Tcore-builder based on either flags or user response
if [ -z "$local_tags" ] && [ -z "$source" ] && [ -z "$user_tag" ]; then
  printf "TorizonCore Builder is not installed. Pulling the latest version from Docker Hub...\n"
  pull_remote=true
  chosen_tag=$latest_remote
elif [ -n "$local_tags" ] && [ -z "$source" ] && [ -z "$user_tag" ]; then
  get_latest_tag "$local_tags"
  latest_local=$latest
  printf "You may have an outdated version installed. Would you like to check for updates online? [y/n] "
  read -r yn
  case $yn in
    [Yy]*)
      pull_remote=true
      chosen_tag=$latest_remote
      ;;
    [Nn]*)
      pull_remote=false
      chosen_tag=$latest_local
      ;;
    *)
      printf "Please answer yes or no.\n"
      tcb_env_setup_cleanup
      return
      ;;
  esac
elif [ "$source" = "local" ]; then
  get_latest_tag "$local_tags"
  latest_local=$latest
  if [ "$latest_local" = "0" ]; then
    printf "Error: no local versions found!\n"
    tcb_env_setup_cleanup
    return
  fi
  pull_remote=false
  chosen_tag=$latest_local
elif [ "$source" = "remote" ]; then
  pull_remote=true
  chosen_tag=$latest_remote
elif [ -n "$user_tag" ]; then
  pull_remote=true
  chosen_tag=$user_tag
fi

# Sets up chosen version of Tcore-builder based on result from above
printf "Setting up TorizonCore Builder with version %s.\n\n" "$chosen_tag"

if [ "$pull_remote" = "true" ]; then
  printf "Pulling TorizonCore Builder...\n"
  if docker pull --platform linux/amd64 torizon/torizoncore-builder:"$chosen_tag"; then
    printf "Done!\n\n"
  else
    printf "Error: could not pull TorizonCore Builder from Docker Hub!\n"
    tcb_env_setup_cleanup
    return
  fi
fi

# if installing latest version, download and source the bash completion script
if [ "$chosen_tag" = "$latest_remote" ]; then
  if wget -q https://raw.githubusercontent.com/toradex/tcb-env-setup/master/torizoncore-builder-completion.bash -O ./torizoncore-builder-completion.bash.tmp 2>/dev/null; then
    # shellcheck disable=SC1091
    . ./torizoncore-builder-completion.bash.tmp 2>/dev/null && rm -rf torizoncore-builder-completion.bash.tmp
  fi
fi

# shellcheck disable=SC2139
alias torizoncore-builder='docker run --rm -it'"$volumes"'-v "$(pwd)":/workdir -v '"$storage"':/storage -v /var/run/docker.sock:/var/run/docker.sock'"$network"'-e TCB_CONTAINER_NAME="tcb_$(date +%s)" --name "tcb_$(date +%s)" '"$*"' torizon/torizoncore-builder:'"$chosen_tag"

printf "Setup complete! TorizonCore Builder is now ready to use.\n"

printf "TorizonCore Builder internal status and image customizations will be stored in %s.\n" "$storage"

printf "********************\n"
printf "Important: When you run TorizonCore Builder, the tool can only access the files inside the current working directory. Files and directories outside of the current working directory, or links to files and directories outside of the current working directory, won't be visible to TorizonCore Builder. So please make sure that, when running TorizonCore Builder, all files and directories passed as parameters are within the current working directory.\n"
printf "Your current working directory is: %s\n" "$(pwd)"
printf "********************\n"
printf "For more information, run 'torizoncore-builder -h' or go to https://developer.toradex.com/knowledge-base/torizoncore-builder-tool\n"

tcb_env_setup_cleanup
unset -f tcb_env_setup_cleanup
