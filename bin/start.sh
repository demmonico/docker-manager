#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script starts all available docker container(s) and networks
#
# FORMAT: ./start.sh [DM_PROJECT]
#-----------------------------------------------------------#

# bin dir & require _common.sh
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DM_BIN_DIR}/_common.sh"



### get arguments
export DM_PROJECT="$1"
if [ $# -gt 1 ]; then
    echo -e "${RED}Error:${NC} invalid parameters list ${YELLOW}${@}${NC}";
    exit
fi



### configure

## set filenames and paths

# filename for hostname environment config
DM_HOST_ENV_CONFIG="host.env"

# get host user info
DM_HOST_USER_NAME="$( whoami )"
DM_HOST_USER_ID="$( id -u "${DM_HOST_USER_NAME}" )"



# include virtual host getter
DM_LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "${DM_BIN_DIR}/_lib_config.sh"

# docker manager name
export DM_NAME="$(getConfig ${DM_LOCAL_CONFIG_FILE} "name")"

# port at host which will be bind with docker network
export DM_HOST_PORT="$(getConfig ${DM_LOCAL_CONFIG_FILE} "host_port" "network")"

# get tokens. Use at app's *.yml
export DMB_APP_GITHUB_TOKEN="$(getConfig "${DM_ROOT_DIR}/config/security/common.yml" "github" "tokens")"
if [ -z "${DMB_APP_GITHUB_TOKEN}" ]; then
    echo -e "${YELLOW}Warning:${NC} parameter ${YELLOW}tokens->github${NC} which could be used at one of projects wasn't defined at config file ${YELLOW}config/security/common.yml${NC}. Something could go wrong ...";
fi



# run startProject projectName
function startProject() {
    local _PROJECT=$1
    local _PROJECT_PREFIX="${DM_NAME}${DM_PROJECT_SPLITTER}${_PROJECT}"

    # check whether folder has docker-compose file
    if [ -f "${DM_PROJECT_DIR}/${_PROJECT}/${DM_COMPOSE_FILENAME}" ]; then
        # check whether container doesn't run yet
        if [ -z "$(docker ps --format="{{ .Names }}" | grep "^${_PROJECT_PREFIX}_")" ]; then

            # setup subdomain's env settings
            if [ "${_PROJECT}" != 'main' ]; then
                touchVhostEnv "${DM_PROJECT_DIR}" "${_PROJECT}"
            else
                touchVhostEnv "${DM_PROJECT_DIR}/${_PROJECT}"
            fi

            # build && up
            docker-compose $( buildComposeFilesLine ${DM_PROJECT_DIR}/${_PROJECT} ) \
                --project-name "${_PROJECT_PREFIX}" up -d --build
        else
            echo "Container named ${_PROJECT} is already running"
        fi
    fi
}



########################################################################
#######################           MAIN           #######################
########################################################################



### init proxy gateway with common network

# run if doesn't exists yet
if [ -z "$(docker ps --format="{{ .Names }}" | grep "^${DM_NAME}_proxy_")" ]; then
    # setup domain's env settings
    touchVhostEnv "${DM_ROOT_DIR}/proxy"
    # build && up
    DM_PROXY_COMPOSE="--file ${DM_ROOT_DIR}/proxy/${DM_COMPOSE_FILENAME}"
    if [ -f "${DM_ROOT_DIR}/proxy/${DM_COMPOSE_FILENAME_LOCAL}" ]; then
        DM_PROXY_COMPOSE="${DM_PROXY_COMPOSE} --file ${DM_ROOT_DIR}/proxy/${DM_COMPOSE_FILENAME_LOCAL}"
    fi
    docker-compose ${DM_PROXY_COMPOSE} --project-name ${DM_NAME} up -d --build
fi



#### init main host with parent domain name
startProject 'main'



### init projects
cd ${DM_PROJECT_DIR}

# single project
if [ ! -z "${DM_PROJECT}" ]; then
    startProject "${DM_PROJECT}"

# all projects
else
    for PROJECT in $( find . -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort )
    do
        # trim /
        PROJECT=${PROJECT%%/}
        # start sub-project
        if [ "${PROJECT}" != 'main' ]; then
            startProject "${PROJECT}"
        fi
    done
fi
