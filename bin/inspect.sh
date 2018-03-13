#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script returns information about containers
#
# FORMAT:
#   ./inspect.sh PROJECT_NAME [PARAMS] PROPERTY_NAME
#
# PARAMS:
#   -s - PROJECT_SERVICE_NAME (default app)
#   -i - PROJECT_SERVICE_INSTANCE_NAME (default 1)
#
#-----------------------------------------------------------#

# bin dir & require _common.sh
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DM_BIN_DIR}/_common.sh"



### get arguments

# project
PROJECT=$1
if [ -z "${PROJECT}" ]; then
    echo -e "${RED}Error:${NC} project's name is required"
    exit
fi

# params
PROJECT_SERVICE_NAME='app'
PROJECT_SERVICE_INSTANCE_NAME='1'
PROPERTY=''

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
        *)
            echo -e "${RED}Error:${NC} invalid option \"${key}\""
            exit
            ;;
    esac
    shift

    # if last param - try to get PROPERTY
    if [ $# -eq 1 ] && [[ "${@}" != -* ]]; then
        PROPERTY="${@}"
        break
    fi
done

if [ -z "${PROPERTY}" ]; then
    echo -e "${RED}Error:${NC} property's name is required"
    exit
fi



# include virtual host getter
LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "${DM_BIN_DIR}/_lib_config.sh"

# docker manager name
DM_NAME="$(getConfig ${LOCAL_CONFIG_FILE} "name")"
# docker container name
CONTAINER="${DM_NAME}${DM_PROJECT_SPLITTER}${PROJECT}_${PROJECT_SERVICE_NAME}_${PROJECT_SERVICE_INSTANCE_NAME}"



# check whether container doesn't run yet
if [ -z "$(docker ps --format="{{ .Names }}" | grep "${CONTAINER}")" ]; then
    echo -e "${RED}Error:${NC} no running containers named \"${CONTAINER}\""
    exit 1
else
    case ${PROPERTY} in
        name)
            echo "${CONTAINER}"
            shift
            ;;
        id)
            echo "$(docker ps -aqf "name=${CONTAINER}")"
            shift
            ;;
        ip)
            NETWORK="${DM_NAME}_common"
            echo "$( \
                docker inspect -f '{{ range $k,$v := .NetworkSettings.Networks }}{{$k}} {{.IPAddress}}|{{end}}' "${CONTAINER}" | \
                sed 's/|$//g' | sed 's/|/\n/g' | \
                grep "${NETWORK}" | sed -E "s/${NETWORK}\s(.*)/\1/" \
            )"
            shift
            ;;
        ips)
            echo 'NETWORK     IP'
            echo "$(docker inspect -f '{{ range $k,$v := .NetworkSettings.Networks }}{{$k}} {{.IPAddress}}|{{end}}' "${CONTAINER}" | sed 's/|$//g' | sed 's/|/\n/g')"
            shift
            ;;
        *)
            echo -e "${RED}Error:${NC} invalid property \"${PROPERTY}\""
            exit
            ;;
    esac
fi
