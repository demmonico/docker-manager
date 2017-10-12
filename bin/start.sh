#!/bin/bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-ci
#
# This script starts all available docker container(s) and networks
#
# Format: ./start.sh [PROXY_ENV=server]
#-----------------------------------------------------------#

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

# set colors
RED='\033[0;31m'
NC='\033[0m' # No Color

# define default PROXY_ENV value
PROXY_ENV="$1"
case "$PROXY_ENV" in
    dev)
     shift ;;
    server)
     shift ;;
    "") PROXY_ENV='server'
     shift ;;
    *)
        echo "Invalid environment '$PROXY_ENV'"
        exit
        ;;
esac


########################
######### MAIN #########
########################

# init proxy gateway with common network
docker-compose --file "$DC_ROOT_DIR/proxy/${PROXY_ENV}_${DC_FILENAME}" --project-name $NETWORK_PREFIX up -d --build

#### init main host with parent domain name
# setup domain name env settings
VIRTUAL_HOST="$(get_vhosts_environment "$DC_ROOT_DIR/$NETWORK_PREFIX/config.yml")"
if [ -z $VIRTUAL_HOST ]; then echo -e "${RED}Error: file proxy/config.yml with domain settings is absent!${NC}" 1>&2; exit 1; fi
echo $VIRTUAL_HOST > "$DC_ROOT_DIR/main/$DC_HOST_ENV_CONFIG"
echo "PROJECT=main" >> "$DC_ROOT_DIR/main/$DC_HOST_ENV_CONFIG"
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
            VIRTUAL_HOST="$(get_vhosts_environment "$DC_ROOT_DIR/$NETWORK_PREFIX/config.yml" "$PROJECT")"
            if [ -z $VIRTUAL_HOST ]; then echo -e "${RED}Error: file proxy/config.yml with domain settings is absent!${NC}" 1>&2; exit 1; fi
            echo $VIRTUAL_HOST > $FILE_ENV_CONFIG
            # project name
            echo "PROJECT=${PROJECT}" >> $FILE_ENV_CONFIG
            # script's owner name
            echo "HOST_USER_NAME=${HOST_USER_NAME}" >> $FILE_ENV_CONFIG
            # script's owner ID
            echo "HOST_USER_ID=${HOST_USER_ID}" >> $FILE_ENV_CONFIG
        fi

        # build && up
        docker-compose --file $DC_FILE up -d --build

    fi
done
