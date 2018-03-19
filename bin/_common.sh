#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script defines contains common used variables
#
#-----------------------------------------------------------#


# set colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color



# DM root dir
DM_ROOT_DIR="$(dirname "${DM_BIN_DIR}")"

# DM projects dir
DM_PROJECT_DIR="${DM_ROOT_DIR}/projects"

# DM project/service name splitter (used for docker labels when start/stop containers)
DM_PROJECT_SPLITTER='000'



# docker compose filename
DM_FILENAME="docker-compose.yml"
DM_FILENAME_OVERRIDE="docker-compose.override.yml"
DM_FILENAME_LOCAL="docker-compose.local.yml"

function buildComposeFilesLine()
{
    local PROJECT_DIR=$1

    # pre-defined compose files
    local DM_COMMON_COMPOSE_DIR="${DM_ROOT_DIR}/config/docker-compose.d"
    local FILES="--file ${PROJECT_DIR}/${DM_FILENAME} --file ${DM_COMMON_COMPOSE_DIR}/networks.yml"

    # additional common used compose files
    local DM_PROJECT_COMPOSE_CONFIG=$( cat ${PROJECT_DIR}/${DM_FILENAME} )
    for FILE in $( find ${DM_COMMON_COMPOSE_DIR} -type f -iname '*.yml' ! -name 'networks.yml' )
    do
        FILENAME=$( basename "${FILE}" )
        FILENAME="${FILENAME%.*}"
        # if we have such named service then apply related docker-compose config
        if [ ! -z "$( echo "${DM_PROJECT_COMPOSE_CONFIG}" | grep "^[[:blank:]]*${FILENAME}:" )" ]; then
            FILES="${FILES} --file ${FILE}"
        fi
    done
    
    # add override yml file
    if [ -f "${PROJECT_DIR}/${DM_FILENAME_OVERRIDE}" ]; then
        FILES="${FILES} --file ${PROJECT_DIR}/${DM_FILENAME_OVERRIDE}"
    fi
    
    # add local yml file
    if [ -f "${PROJECT_DIR}/${DM_FILENAME_LOCAL}" ]; then
        FILES="${FILES} --file ${PROJECT_DIR}/${DM_FILENAME_LOCAL}"
    fi

    echo ${FILES}
}
