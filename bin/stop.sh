#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script stops docker container(s) and unused networks
# If PROJECT_NAME doesn't exists then script will stop all exists containers and unused networks
#
# FORMAT:
#   ./stop.sh [OPTIONS] [-n PROJECT_NAME]
#
# OPTIONS:
#   -c - remove containers after they stops
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
    case $key in
        -c) isRemoveContainers='true';;
        -a) isRemoveAll='true';;
        -f) isForceMode='-f';;
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



# docker compose filename
DM_FILENAME="docker-compose.yml"

# include virtual host getter
LOCAL_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
source "$DM_BIN_DIR/_lib_config.sh"

# docker manager name
export DM_NAME="$(getConfig ${LOCAL_CONFIG_FILE} "name")"



# HOTFIX warning
export GITHUB_TOKEN=""



# one/all processing
if [ ! -z "${PROJECT}" ]
then
    # if project exists
    if [ -d "${DM_PROJECT_DIR}/${PROJECT}" ]
    then
        DM_FILE="${DM_PROJECT_DIR}/${PROJECT}/${DM_FILENAME}"

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

        CONFIGS="--file ${DM_FILE} --file ${DM_ROOT_DIR}/proxy/common-network.yml"
        docker-compose ${CONFIGS} --project-name "${DM_NAME}${DM_PROJECT_SPLITTER}${PROJECT}" ${COMMAND}
    else
        echo "Invalid project - ${PROJECT}"
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
docker network prune -f
