#!/bin/bash
# This script starts all available docker container(s) and networks

## set filenames and paths
# docker compose filename
DC_FILENAME="docker-compose.yml"
# filename for hostname environment config
DC_HOST_ENV_CONFIG="host.env"
# bin dir
DC_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# docker containers root dir
DC_ROOT_DIR="$(dirname "$DC_BIN_DIR")"

# get host user info
HOST_USER_NAME="$( whoami )"
HOST_USER_ID="$( id -u "${HOST_USER_NAME}" )"

# common network prefix used when create network inside the proxy container
NETWORK_PREFIX="proxy"

# include virtual host getter
source "$DC_BIN_DIR/vhosts.sh"


########################
######### MAIN #########
########################

# init proxy gateway with common network
docker-compose --file "$DC_ROOT_DIR/proxy/$DC_FILENAME" --project-name $NETWORK_PREFIX up -d --build

#### init main host with parent domain name
# setup domain name env settings
echo "$(get_vhosts_environment "$DC_ROOT_DIR/$NETWORK_PREFIX/config.yml")" > "$DC_ROOT_DIR/main/$DC_HOST_ENV_CONFIG"
echo "HOST_USER_NAME=${HOST_USER_NAME}" >> "$DC_ROOT_DIR/main/$DC_HOST_ENV_CONFIG"
echo "HOST_USER_ID=${HOST_USER_ID}" >> "$DC_ROOT_DIR/main/$DC_HOST_ENV_CONFIG"
# build && up
docker-compose --file "$DC_ROOT_DIR/main/$DC_FILENAME" up -d --build

# init projects
DC_PROJECT_DIR="$DC_ROOT_DIR/projects"
cd $DC_PROJECT_DIR
for PROJECT in $(ls -d */)
do
    # trim /
    PROJECT=${PROJECT%%/}

    # check whether docker project
    DC_FILE="$DC_PROJECT_DIR/$PROJECT/$DC_FILENAME"
    if [ -f $DC_FILE ]; then

        # setup subdomain env settings
        FILE_ENV_CONFIG="$DC_PROJECT_DIR/$PROJECT/$DC_HOST_ENV_CONFIG"
        if [ ! -f $FILE_ENV_CONFIG ]; then
            # virtual hosts
            echo "$(get_vhosts_environment "$DC_ROOT_DIR/$NETWORK_PREFIX/config.yml" "$PROJECT")" > $FILE_ENV_CONFIG
            # script's owner name
            echo "HOST_USER_NAME=${HOST_USER_NAME}" >> $FILE_ENV_CONFIG
            # script's owner ID
            echo "HOST_USER_ID=${HOST_USER_ID}" >> $FILE_ENV_CONFIG
        fi

        # build && up
        docker-compose --file $DC_FILE up -d --build

    fi
done
