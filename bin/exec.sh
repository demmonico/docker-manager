#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script exec command inside the project
#
# FORMAT:
#   ./exec.sh DM_PROJECT [PARAMS][-c COMMAND [PARAMS] (default bash)]
#
# PARAMS:
#   -s - DM_PROJECT_SERVICE_NAME (default app)
#   -i - DM_PROJECT_SERVICE_INSTANCE_NAME (default 1)
#   -u - DMC_USER (default "dm" user)
#
#-----------------------------------------------------------#

# bin dir & require _common.sh
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DM_BIN_DIR}/_common.sh"



### get arguments

# project
DM_PROJECT=$1
if [ -z "${DM_PROJECT}" ]; then
    echo -e "${RED}Error:${NC} project's name is required"
    exit
fi

# params
DM_PROJECT_SERVICE_NAME='app'
DM_PROJECT_SERVICE_INSTANCE_NAME='1'
DMC_USER=''
COMMAND='bash'

while [[ $# -gt 0 ]]
do
    key="$1"
    case "${key}" in
        "${DM_PROJECT}")
            # nothing do
            ;;
        -s)
            if [ ! -z "$2" ]; then
                export DM_PROJECT_SERVICE_NAME="$2"
            fi
            shift
            ;;
        -i)
            if [ ! -z "$2" ]; then
                export DM_PROJECT_SERVICE_INSTANCE_NAME="$2"
            fi
            shift
            ;;
        -u)
            if [ ! -z "$2" ]; then
                export DMC_USER="$2"
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
if [ -z "${DMC_USER}" ]; then
    #if [ "${DM_PROJECT_SERVICE_NAME}" == 'app' ]; then
    #    DMC_USER=$UID
    #else
    #    DMC_USER='root'
    #fi
    DMC_USER='dm'
fi

# include virtual host getter
DM_LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "${DM_BIN_DIR}/_lib_config.sh"

# docker manager name
DM_NAME="$(getConfig ${DM_LOCAL_CONFIG_FILE} "name")"
# docker container name
CONTAINER="${DM_NAME}${DM_PROJECT_SPLITTER}${DM_PROJECT}_${DM_PROJECT_SERVICE_NAME}_${DM_PROJECT_SERVICE_INSTANCE_NAME}"



# check whether container doesn't run yet
if [ -z "$(docker ps --format="{{ .Names }}" | grep "${CONTAINER}")" ]; then
    echo -e "${RED}Error:${NC} no running containers named \"${CONTAINER}\""
    exit 1
else
    # check whether COMMAND is pre-defined cmd_alias
    readarray -t COMMAND_ALIASES <<<"$(getConfig ${DM_LOCAL_CONFIG_FILE} 'cmd_aliases' 'container')"
    for ALIAS in "${COMMAND_ALIASES[@]}"
    do
        ALIAS_NAME="$( echo "${ALIAS}" | sed -r 's/=.+$//' )"
        ALIAS_CMD="$( echo "${ALIAS}" | sed -r 's/^.+=//' )"
        # validate alias
        if [ ! -z "${ALIAS_NAME}" ] && [ ! -z "${ALIAS_NAME}" ]; then
            # if match then replace alias with real command
            if [ "${COMMAND}" == "${ALIAS_NAME}" ]; then
                COMMAND="${ALIAS_CMD}"
                break
            fi
        fi
    done

    # exec COMMAND
    docker exec -ti --user ${DMC_USER} ${CONTAINER} ${COMMAND}
fi
