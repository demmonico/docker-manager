#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script starts all available docker container(s) and networks
#
# FORMAT: ./start.sh [-n PROJECT_NAME]
#-----------------------------------------------------------#



### get arguments
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -n)
            if [ ! -z "$2" ]; then
                export PROJECT="$2"
            fi
            shift
            ;;
        *)
            echo "Invalid option -$1"
            exit
            ;;
    esac
        shift
done



### configure

## set filenames and paths
# docker compose filename
DM_FILENAME="docker-compose.yml"
# filename for hostname environment config
DM_HOST_ENV_CONFIG="host.env"
# bin dir
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# docker manager root dir
DM_ROOT_DIR="$(dirname "${DM_BIN_DIR}")"
# DM projects dir
DM_PROJECT_DIR="${DM_ROOT_DIR}/projects"
# DM project/service name splitter (used for docker labels when start/stop containers)
DM_PROJECT_SPLITTER='000'

# get host user info
HOST_USER_NAME="$( whoami )"
HOST_USER_ID="$( id -u "${HOST_USER_NAME}" )"

# set colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color



# include virtual host getter
LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "$DM_BIN_DIR/lib_config.sh"

# docker manager name
export DM_NAME="$(getConfig ${LOCAL_CONFIG_FILE} "name")"

# port at host which will be bind with docker network
export DM_HOST_PORT="$(getConfig ${LOCAL_CONFIG_FILE} "host_port" "network")"

# get tokens. Use at app's *.yml
export GITHUB_TOKEN="$(getConfig "${DM_ROOT_DIR}/config/security/common.yml" "github" "tokens")"
if [ -z "${GITHUB_TOKEN}" ]; then
    echo -e "${YELLOW}Warning:${NC} parameter ${YELLOW}tokens->github${NC} which could be used at one of projects wasn't defined at config file ${YELLOW}config/security/common.yml${NC}. Something could go wrong ...";
fi



# run startProject projectName
function startProject() {
    local _PROJECT=$1
    local _PROJECT_PREFIX="${DM_NAME}${DM_PROJECT_SPLITTER}${_PROJECT}"

    # check whether folder has docker-compose file
    DM_FILE="${DM_PROJECT_DIR}/${_PROJECT}/${DM_FILENAME}"
    if [ -f ${DM_FILE} ]; then
        # check whether container doesn't run yet
        if [ -z "$(docker ps --format="{{ .Names }}" | grep "^${_PROJECT_PREFIX}_")" ]; then

            # setup subdomain's env settings
            if [ "${_PROJECT}" != 'main' ]; then
                touchVhostEnv "${DM_PROJECT_DIR}" "${_PROJECT}"
            else
                touchVhostEnv "${DM_PROJECT_DIR}/${_PROJECT}"
            fi

            # build && up
            docker-compose --file ${DM_FILE} \
                --file "${DM_ROOT_DIR}/proxy/common-network.yml" \
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
    docker-compose --file "${DM_ROOT_DIR}/proxy/${DM_FILENAME}" --project-name ${DM_NAME} up -d --build
fi



#### init main host with parent domain name
startProject 'main'



### init projects
cd ${DM_PROJECT_DIR}

# single project
if [ ! -z "${PROJECT}" ]; then
    startProject "${PROJECT}"

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
