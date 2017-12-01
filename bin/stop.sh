#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script stops docker container(s) and unused networks
# If PROJECT_NAME doesn't exists then script will stop all exists containers and unused networks
#
# Format: ./stop.sh [PARAMS] [-n PROJECT_NAME]
# Params:
#   -c - remove containers after they stops
#   -a - remove all containers and their images after they stops
#   -f - forced mode
#-----------------------------------------------------------#



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

# bin dir
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# docker containers root dir
DM_ROOT_DIR="$(dirname "${DM_BIN_DIR}")"
# dir of projects
DM_PROJECT_DIR="${DM_ROOT_DIR}/projects"



# HOTFIX warning
export GITHUB_TOKEN=""



# one/all processing
if [ ! -z "${PROJECT}" ]
then
    # if project exists
    if [ -d "${DM_PROJECT_DIR}/${PROJECT}" ]
    then
        cd "${DM_PROJECT_DIR}/${PROJECT}"
        # remove all
        if [ ! -z "${isRemoveAll}" ]
        then
            docker-compose down --rmi all
        # remove containers
        elif [ ! -z "${isRemoveContainers}" ]
        then
            docker-compose down
        # only stop containers
        else
            docker-compose stop
        fi
    else
        echo "Invalid project - ${PROJECT}"
    fi
else
    cd "${DM_ROOT_DIR}"
    CONTAINERS=$(docker ps -a -q)

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
