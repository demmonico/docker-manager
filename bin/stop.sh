#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script stops docker container(s) and unused networks
# If DM_PROJECT doesn't exists then script will stop all exists containers and unused networks
#
# FORMAT:
#   ./stop.sh [OPTIONS] [DM_PROJECT]
#
# OPTIONS:
#   -c - remove containers after they stops (always started from HOTFIX)
#   -a - remove all containers and all images after they stops
#   -f - forced mode (see Docker documentation)
#-----------------------------------------------------------#

# bin dir & require _common.sh
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DM_BIN_DIR}/_common.sh"



# get params
while [[ $# -gt 0 ]]
do
    key="$1"
    case ${key} in
        -c) isRemoveContainers='true';;
        -a) isRemoveAll='true';;
        -f) isForceMode='-f';;
        *)
            # extract DM_PROJECT
            if [ $# -eq 1 ] && [[ "${key}" != -* ]]; then
                export DM_PROJECT="${key}"
            else
                echo -e "${RED}Error:${NC} invalid parameters list ${YELLOW}${@}${NC}";
                exit
            fi
            ;;
    esac
        shift
done



# include virtual host getter
DM_LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "$DM_BIN_DIR/_lib_config.sh"

# docker manager name
export DM_NAME="$(getConfig ${DM_LOCAL_CONFIG_FILE} "name")"



# HOTFIX warning
export DMB_APP_GITHUB_TOKEN=""



# one/all processing
if [ ! -z "${DM_PROJECT}" ]
then
    # if project exists
    if [ -d "${DM_PROJECT_DIR}/${DM_PROJECT}" ]
    then
        # remove all
        if [ ! -z "${isRemoveAll}" ]
        then
            COMMAND='down --rmi all'
        # remove containers
        elif [ ! -z "${isRemoveContainers}" ]
        then
            COMMAND='down'
        # only stop containers
        else
            COMMAND='stop'
        fi

        docker-compose $( buildComposeFilesLine ${DM_PROJECT_DIR}/${DM_PROJECT} ) \
            --project-name "${DM_NAME}${DM_PROJECT_SPLITTER}${DM_PROJECT}" ${COMMAND}
    else
        echo -e "${RED}Error:${NC} invalid project ${YELLOW}${DM_PROJECT}${NC}";
        exit
    fi
else
    cd "${DM_ROOT_DIR}"

    # find all containers
    #CONTAINERS=$(docker ps -a -q)

    ### attempt with project name
    #PROJ=dev; PROJ=$(docker ps -a --format '{{ .Label "com.docker.compose.project" }}' | grep "^${PROJ}${DM_PROJECT_SPLITTER}\|^${PROJ}$" | sort | uniq);
    #for PR in ${PROJ}
    #do
    #    CC=$( docker ps -a -q --filter "label=com.docker.compose.project=${PR}" )
    #done

    # find all containers related to this manager
    CONTAINERS=$(docker ps -a --format '{{.ID}} {{.Names}} ==={{.Label "com.docker.compose.project"}}===' | grep "===${DM_NAME}${DM_PROJECT_SPLITTER}.*===\|===${DM_NAME}===" | awk '{print $1}' );

    # stop all containers
    echo "Stopped containers (id):"
    docker stop ${CONTAINERS}

    # remove all containers
    if [ ! -z "${isRemoveAll}" ] || [ ! -z "${isRemoveContainers}" ]
    then
        echo "Removed containers (id):"
        docker rm ${isForceMode} ${CONTAINERS}
    fi

    # remove all images
    if [ ! -z "${isRemoveAll}" ]
    then
        echo "Removed images (id):"
        docker rmi ${isForceMode} $(docker images -q)
    fi
fi;



# remove all unused networks
# do not run this cause an error related with stop-start containers based on multi docker-compose files
if [ ! -z "${isRemoveAll}" ] || [ ! -z "${isRemoveContainers}" ]; then
    docker network prune -f
fi
