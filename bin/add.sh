#!/bin/bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-ci
#
# This script build and add docker container and his internal networks and connect them to the external docker network
#
# Format: ./add.sh PROJECT_NAME
#-----------------------------------------------------------#

## set filenames and paths
# docker compose filename
DC_FILENAME="docker-compose.yml"
# filename for hostname environment config
DC_HOST_ENV_CONFIG="host.env"
# bin dir
DC_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# docker containers root dir
DC_ROOT_DIR="$(dirname "$DC_BIN_DIR")"

# get host user info
HOST_USER_NAME="$( whoami )"
HOST_USER_ID="$( id -u "${HOST_USER_NAME}" )"

# common network prefix used when create network inside the proxy container
NETWORK_PREFIX="proxy"

# include virtual host getter
source "$DC_BIN_DIR/vhosts.sh"

# set colors
RED='\033[0;31m'
NC='\033[0m' # No Color



########################
######### MAIN #########
########################

PROJECT=$1

# validate for empty
if [ -z "$PROJECT" ]
then
  echo "Project name cannot be empty"
  exit
fi

# validate for active status container
for i in "$(docker ps --format "{{.Names}}")"
do
  if [ "$PROJECT" == "$i" ]
  then
    echo "Container named $PROJECT is already active"
    exit
  fi
done

### init project
DC_PROJECT_DIR="$DC_ROOT_DIR/projects"
cd $DC_PROJECT_DIR

# setup subdomain env settings
FILE_ENV_CONFIG="$DC_PROJECT_DIR/$PROJECT/$DC_HOST_ENV_CONFIG"
if [ ! -f $FILE_ENV_CONFIG ]; then
    # virtual hosts
    VIRTUAL_HOST="$(get_vhosts_environment "$DC_ROOT_DIR/$NETWORK_PREFIX/config.yml" "$PROJECT")"
    if [ -z $VIRTUAL_HOST ]; then echo -e "${RED}Error: file proxy/config.yml with domain settings is absent!${NC}" 1>&2; exit 1; fi
    echo $VIRTUAL_HOST > $FILE_ENV_CONFIG
    # project name
    echo "PROJECT=${PROJECT}" >> $FILE_ENV_CONFIG
    # script's owner name
    echo "HOST_USER_NAME=${HOST_USER_NAME}" >> $FILE_ENV_CONFIG
    # script's owner ID
    echo "HOST_USER_ID=${HOST_USER_ID}" >> $FILE_ENV_CONFIG
fi

# build && up

# run get_param_environment config_file_to_parse param_name category_name
function get_env_param() {

    # parse hosts config file
    local YAML_CONFIG_FILE=$1
    local PARAM_NAME=$2
    local CATEGORY_NAME=$3
    local YAML_PARSER_FILE="${DC_BIN_DIR}/parse_yaml.sh"

    eval "$(${YAML_PARSER_FILE} ${YAML_CONFIG_FILE} config_)"

    CATEGORY_NAME=${CATEGORY_NAME:+"${CATEGORY_NAME}_"}
    param_full_name="config_${CATEGORY_NAME}${PARAM_NAME}"

    echo "${!param_full_name}"
}

export GITHUB_TOKEN="$(get_env_param "$DC_ROOT_DIR/config/security/common.yml" "github" "tokens")"

docker-compose --file "$DC_PROJECT_DIR/$PROJECT/$DC_FILENAME" up -d --build
