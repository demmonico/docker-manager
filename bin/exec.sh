#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script exec command inside the project
#
# FORMAT:
#   ./exec.sh PROJECT_NAME [PARAMS][-c COMMAND_WITH_PARAMS (default bash)]
#
# PARAMS:
#   -s - PROJECT_SERVICE_NAME (default app)
#   -i - PROJECT_SERVICE_INSTANCE_NAME (default 1)
#   -u - CONTAINER_USER_NAME (default UID=1000 for app services and root for all)
#
#-----------------------------------------------------------#

# bin dir & require _common.sh
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DM_BIN_DIR}/_common.sh"



### get arguments

# project
PROJECT=$1
if [ -z PROJECT ]; then
    echo -e "${RED}Error:${NC} project's name is required"
    exit
fi

# params
PROJECT_SERVICE_NAME='app'
PROJECT_SERVICE_INSTANCE_NAME='1'
CONTAINER_USER_NAME=''
COMMAND='bash'
while [[ $# -gt 0 ]]
do
    key="$1"
    case "${key}" in
        "${PROJECT}")
            # nothing do
            ;;
        -s)
            if [ ! -z "$2" ]; then
                export PROJECT_SERVICE_NAME="$2"
            fi
            shift
            ;;
        -i)
            if [ ! -z "$2" ]; then
                export PROJECT_SERVICE_INSTANCE_NAME="$2"
            fi
            shift
            ;;
        -u)
            if [ ! -z "$2" ]; then
                export CONTAINER_USER_NAME="$2"
            fi
            shift
            ;;
        -c)
            shift
            COMMAND="${@}"
            break
            ;;
        *)
            echo -e "${RED}Error:${NC} invalid option \"${key}\""
            exit
            ;;
    esac
    shift
done

# re-assign user for app containers
if [ -z "${CONTAINER_USER_NAME}" ]; then
    if [ "${PROJECT_SERVICE_NAME}" == 'app' ]; then
        CONTAINER_USER_NAME=$UID
    else
        CONTAINER_USER_NAME='root'
    fi
fi

# include virtual host getter
LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "${DM_BIN_DIR}/_lib_config.sh"

# docker manager name
DM_NAME="$(getConfig ${LOCAL_CONFIG_FILE} "name")"



### search container

CONTAINER="${DM_NAME}${DM_PROJECT_SPLITTER}${PROJECT}_${PROJECT_SERVICE_NAME}_${PROJECT_SERVICE_INSTANCE_NAME}"

# check whether container doesn't run yet
if [ -z "$(docker ps --format="{{ .Names }}" | grep "${CONTAINER}")" ]; then
    echo -e "${RED}Error:${NC} no running containers named \"${CONTAINER}\""
    exit 1
else
    docker exec -ti --user ${CONTAINER_USER_NAME} ${CONTAINER} ${COMMAND}
fi
