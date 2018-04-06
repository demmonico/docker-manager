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
            # try to return quotes to cmd
            # TODO-dep
            if [ -z "$( echo "$*" | grep '\s' )" ]; then
                # simple command
                COMMAND="${@}"
            else
                # command with quotes
                oldIFS="$IFS"
                IFS="#${IFS}"
                COMMAND="$( echo "$*" | sed -E 's/(#|^)?([^\s^#]*\s[^\s^#]*)(#|$)?/#"\2"#/g' | sed 's/#/ /g' )"
                IFS="${oldIFS}"
            fi
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
if [ "${DM_PROJECT}" == "${DM_NAME}_proxy" ]; then
    CONTAINER="${DM_NAME}_proxy_${DM_PROJECT_SERVICE_INSTANCE_NAME}"
else
    CONTAINER="${DM_NAME}${DM_PROJECT_SPLITTER}${DM_PROJECT}_${DM_PROJECT_SERVICE_NAME}_${DM_PROJECT_SERVICE_INSTANCE_NAME}"
fi



# check whether container doesn't run yet
if [ -z "$(docker ps --format="{{ .Names }}" | grep "${CONTAINER}")" ]; then
    echo -e "${RED}Error:${NC} no running containers named \"${CONTAINER}\""
    exit 1
else

    # check whether COMMAND is pre-defined cmd_alias (is prefixed with lib/ and which related script exists in DMC_INSTALL_DIR prefixed with exec_cmd_)
    if [[ "${COMMAND}" =~ ^lib//* ]]; then
        CMD_SCRIPT_NAME="exec_cmd_$( echo "${COMMAND}" | sed 's#lib/##g' | sed 's#/#_#g' | sed -E 's#^([A-Za-z0-9_]+)[[:space:]]*.*$#\1#g' ).sh"
        FIND_COMMAND="find \"\${DMC_INSTALL_DIR}\" -type f -iname \"${CMD_SCRIPT_NAME}\""
        LIB_SCRIPT="$( docker exec ${CONTAINER} bash -c "${FIND_COMMAND}" | head -n 1 )"
        if [ -z "${LIB_SCRIPT}" ]; then
            echo -e "${RED}Error:${NC} lib command ${YELLOW}${CMD_SCRIPT_NAME}${NC} was no found at \"${CONTAINER}\""
            exit 1
        fi
        LIB_SCRIPT_PARAMS="$( echo "${COMMAND}" | sed 's#/#_#g' | sed -E 's#^[A-Za-z0-9_]+[[:space:]]*(.*)$#\1#g' )"
        COMMAND="${LIB_SCRIPT} ${LIB_SCRIPT_PARAMS}"
    else
        # check whether COMMAND is pre-configured cmd_alias
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
    fi

    # exec COMMAND
    [ "${COMMAND}" == "bash" ] && OPTION_INTERACTIVE='-ti' || OPTION_INTERACTIVE=''

    docker exec ${OPTION_INTERACTIVE} -e DMC_EXEC_NAME=${CONTAINER} \
        --user ${DMC_USER} \
        -e COLUMNS=`tput cols` -e LINES=`tput lines` \
        ${CONTAINER} ${COMMAND}
fi
