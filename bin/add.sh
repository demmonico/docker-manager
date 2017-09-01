#!/bin/bash

## set filenames and paths
# docker compose filename
DC_FILENAME="docker-compose.yml"
# filename for hostname environment config
DC_HOST_ENV_CONFIG="host.env"
# bin dir
DC_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# docker containers root dir
DC_ROOT_DIR="$(dirname "$DC_BIN_DIR")"
# dir of projects
DC_PROJECT_DIR="$DC_ROOT_DIR/projects"

# common network prefix used when create network inside the proxy container
NETWORK_PREFIX="proxy"

# include virtual host getter
source "$DC_BIN_DIR/vhosts.sh"



########################
######### MAIN #########
########################

PROJECT=$1

# validate for empty
if [ -z "$PROJECT" ]
then
  echo "Project name cannot be empty"
  exit
fi

# validate for active status container
for i in "$(docker ps --format "{{.Names}}")"
do
  if [ "$PROJECT" == "$i" ]
  then
    echo "Container named $PROJECT is already active"
    exit
  fi
done

### init project
cd $DC_PROJECT_DIR

# setup subdomain env settings
FILE_ENV_CONFIG="$DC_PROJECT_DIR/$PROJECT/$DC_HOST_ENV_CONFIG"
if [ ! -f $FILE_ENV_CONFIG ]; then
   echo "$(get_vhosts_environment "$DC_ROOT_DIR/$NETWORK_PREFIX/config.yml" "$PROJECT")" > $FILE_ENV_CONFIG
fi

# build && up
docker-compose --file ./$PROJECT/$DC_FILENAME up -d --build
