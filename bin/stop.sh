#!/bin/bash

# bin dir
DC_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# docker containers root dir
DC_ROOT_DIR="$(dirname "$DC_BIN_DIR")"
# dir of projects
DC_PROJECT_DIR="$DC_ROOT_DIR/projects"



PROJECT=$1
cd "$DC_ROOT_DIR"
if [ ! -z "$PROJECT" ]
then
    # set colors
#    GREEN='\033[0;32m'
#    NC='\033[0m' # No Color
    # stop container
#    echo -n "Stopping $PROJECT ... "
#    docker stop "$PROJECT" > /dev/null 2>&1
#    echo -e "${GREEN}done${NC}"

    # remove container
#    echo -n "Removing $PROJECT ... "
#    docker rm -f "$PROJECT" > /dev/null 2>&1
#    echo -e "${GREEN}done${NC}"

    # docker compose down
    cd "$DC_PROJECT_DIR/$PROJECT"
#    docker-compose down -rmi all > /dev/null 2>&1
#    docker-compose down --rmi all
    docker-compose down
else
    cd "$DC_ROOT_DIR"

    # stop all containers
    echo "Stopped containers (id):"
    docker stop $(docker ps -a -q)

    # remove all containers
    echo "Removed containers (id):"
    docker rm -f $(docker ps -a -q)

    #docker rmi $(docker images -q)

    # remove all unused networks
    #docker network rm $(docker network list -q)
    docker network prune -f
fi;
