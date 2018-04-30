#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script install Docker Manager and settings up environment
#
# FORMAT:
#   sudo ./install.sh [OPTIONS] -h DM_HOST_NAME [-n DM_NAME] [-p DM_HOST_PORT]
#
# OPTIONS:
#   -c - configurate only (no preparing environment actions)
#   -a - add DM to startup (default true for server env and false for local env)
#
#-----------------------------------------------------------#

# bin dir & require _common.sh
DM_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DM_BIN_DIR}/_common.sh"


### configure

# check for root permission
USER=${SUDO_USER:-$(whoami)}
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error:${NC} please run as root"
    exit
fi;

# docker manager root dir name
DM_ROOT_DIR_NAME="$(basename "${DM_ROOT_DIR}")"
# docker manager's name
DM_NAME=${DM_ROOT_DIR_NAME}



### get arguments
DM_HOST_PORT=80
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -c) isConfigurateOnly='true';;
        -a) isAutostart='true';;
        -h|--host)
            if [ ! -z "$2" ]; then
                DM_HOST_NAME="$2"
            fi
            shift
            ;;
        -n|--name)
            if [ ! -z "$2" ]; then
                DM_NAME="$2"
            fi
            shift
            ;;
        -p|--port)
            if [ ! -z "$2" ]; then
                DM_HOST_PORT="$2"
            fi
            shift
            ;;
        *)
            echo -e "${RED}Error:${NC} invalid option -$1"
            exit
            ;;
    esac
        shift
done

# validate DM_HOST_NAME
if [ -z "${DM_HOST_NAME}" ]; then
    echo -e "${RED}Error:${NC} empty host name (-h parameter)"
    exit
fi

# validate is DM_HOST_PORT free
if [ ! -z "$( netstat -ln | grep ":${DM_HOST_PORT} " )" ]; then
    echo -e "${RED}Error:${NC} port ${DM_HOST_PORT} is busy"
    exit
fi

# validate is DM_NAME free and match [A-Za-z0-9] pattern
until
    [ ! -z "${DM_NAME}" ] && [ "${DM_NAME}" == "${DM_NAME//[^A-Za-z0-9]/}" ] &&
    [ -z "$( docker ps --format '{{.Label "com.docker.compose.project"}}' | grep "^${DM_NAME}\$" )" ]
do
    if [ -z "$( docker ps --format '{{.Label "com.docker.compose.project"}}' | grep "^${DM_NAME}\$" )" ]; then
        REASON="should match [A-Za-z0-9] pattern"
    else
        REASON="already exists"
    fi
    echo -n -e "${RED}Error:${NC} DM name ${YELLOW}${DM_NAME:-''}${NC} ${REASON}. Please re-enter: "
    read -p '' DM_NAME
done;

#-----------------------------------------------------------#



### generate config file
echo -n -e "${BLUE}Info:${NC} ${GREEN}generating config file ... ${NC}";
DM_CONFIG_FILE="${DM_ROOT_DIR}/config/local.yml"
DM_CONFIG_FILE_EXAMPLE="${DM_ROOT_DIR}/config/local-example.yml"
sudo cp -p ${DM_CONFIG_FILE_EXAMPLE} ${DM_CONFIG_FILE}
VARS=("DM_NAME" "DM_HOST_NAME" "DM_HOST_PORT")
for VAR in "${VARS[@]}"
do
    sed -i "s|{{ ${VAR} }}|${!VAR}|g" ${DM_CONFIG_FILE}
done
echo -e "${GREEN}done${NC}";



### prepare environment

isLocalEnv="$([ ! -z "$( netstat -ln | grep ":80 " )" ] && [ ! -z "$( dpkg --get-selections | grep apache )" ] && echo 'true' )";



#-----------------------------------------------------------#
# add DM to startup for server environment or if

# set flag true for server env
[ -z "${isLocalEnv}" ] && isAutostart='true'
if [ ! -z "${isAutostart}" ]; then
    echo -n -e "${BLUE}Info:${NC} ${GREEN}inserting command to startup ... ${NC}";
    source "${DM_BIN_DIR}/_startup.sh"
    r=$( add_startup "${DM_ROOT_DIR}/dm start" 1 )
    if [ "${r}" == "done" ]; then
        echo -e "${GREEN}${r}${NC}";
    elif [ "${r}" == "skip" ]; then
        echo -e "${YELLOW}${r}${NC}";
    else
        echo -e "${RED}${r}${NC}";
    fi
fi

#-----------------------------------------------------------#



# exit if configurate only mode
if [ ! -z "$isConfigurateOnly" ]; then
    exit
fi;



#-----------------------------------------------------------#
# local environment
# update Apache config if it is installed and is listen default port 80
# (preferable use on the development environment: Apache at host machine + Docker Manager inside Apache as virtual host)
if [ ! -z "${isLocalEnv}" ]; then

    # check for www placement
    if [ "${DM_ROOT_DIR}" == "/var/www/${DM_HOST_NAME}" ]; then
        echo -e "${BLUE}Info:${NC} web-server Apache detected. Start configure Apache to make website available";

        # set apache site config
        echo -n -e "${BLUE}Info:${NC} writing Apache config ... ";
        (
            echo "<VirtualHost *:80>";
            echo "    ServerName ${DM_HOST_NAME}";
            echo "    ServerAlias *.${DM_HOST_NAME}";
            echo "    DocumentRoot ${DM_ROOT_DIR}";
            echo "    ";
            echo "    RewriteEngine On";
            echo "    ";
            echo "    ProxyPreserveHost On";
            echo "    UseCanonicalName On";
            echo "    ProxyPass / http://0.0.0.0:${DM_HOST_PORT}/";
            echo "    ProxyPassReverse / http://0.0.0.0:${DM_HOST_PORT}/";
            echo "    ";
            echo "    ErrorLog ${DM_ROOT_DIR}/log/error.log";
            echo "    CustomLog ${DM_ROOT_DIR}/log/access.log combined";
            echo "</VirtualHost>";
        ) | tee /etc/apache2/sites-available/${DM_HOST_NAME}.conf >/dev/null 2>&1;
        echo -e "${GREEN}done${NC}";

        # config apache
        echo -e "${BLUE}Info:${NC} enabling Apache mod_proxy and proxy_http ... ";
        sudo a2enmod proxy && sudo a2enmod proxy_http
        echo -e "${GREEN}done${NC}";

        # restart apache
        echo -n -e "${BLUE}Info:${NC} restart Apache service ... ";
        sudo service apache2 restart
        echo -e "${GREEN}done${NC}";

        # update hosts file
        echo -n -e "${BLUE}Info:${NC} updating available hosts ... ";
        # add/update host
        function updateHostsFile() {
            local SITENAME=$1;
            # remove if exists
            local domain=`echo "${SITENAME}" | sed 's/\./\\\\./g'`;        # shield dots
            sed -i "/^127\.0\.0\.1\s*$domain$/d" /etc/hosts;               # remove lines by pattern
            # add
            echo "127.0.0.1        ${SITENAME}" | sudo tee -a /etc/hosts >/dev/null 2>&1;
        }
        # update main host
        if ! grep -q "127.0.0.1        ${DM_HOST_NAME}" /etc/hosts
        then
            updateHostsFile "${DM_HOST_NAME}"
        fi
        # update sud-domains
        for PROJECT in $( find "${DM_PROJECT_DIR}" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort )
        do
            updateHostsFile "${PROJECT%%/}.${DM_HOST_NAME}"
        done
        echo -e "${GREEN}done${NC}";
    fi

fi

#-----------------------------------------------------------#



### install software

DMI_VERSION_DOCKER_COMPOSE=${DMI_VERSION_DOCKER_COMPOSE:-'1.17.0'}
echo -e "${BLUE}Info:${NC} updating repositories ... "
sudo apt-get update
echo -e "${BLUE}Info:${NC} install software ... "
{ command -v docker > /dev/null 2>&1 && echo -e "${BLUE}Info:${NC} ${GREEN}docker${NC} is already installed"; } || \
    { \
        # setup repository
        sudo apt-get -y install apt-transport-https \
            ca-certificates \
            curl \
            gnupg2 \
            software-properties-common && \
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add - && \
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" && \
        # install docker
        sudo apt-get update && \
        sudo apt-get -y install docker-ce && \
        # FIX error Docker daemon connection
        { \
            # 1. Create the docker group.
            sudo groupadd docker; \
            # 2. Add your user to the docker group.
            sudo usermod -aG docker ${USER}; \
            # 3. Log out and log back in so that your group membership is re-evaluated.
            # TODO improve this
            #exec sudo su -l ${USER} </dev/null >/dev/null 2>&1; \
        } \
    } && \
{ command -v docker-compose > /dev/null 2>&1 && echo -e "${BLUE}Info:${NC} ${GREEN}docker-compose${NC} is already installed"; } || { \
    sudo curl -L https://github.com/docker/compose/releases/download/${DMI_VERSION_DOCKER_COMPOSE}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose && \
    sudo chmod +x /usr/local/bin/docker-compose; \
}



#-----------------------------------------------------------#
# server environment

if [ -z "${isLocalEnv}" ]; then
    { command -v mc > /dev/null 2>&1 && echo -e "${BLUE}Info:${NC} ${GREEN}mc${NC} is already installed"; } || \
        sudo apt-get -y install mc && \
    { command -v ssh > /dev/null 2>&1 && echo -e "${BLUE}Info:${NC} ${GREEN}openssh-client${NC} is already installed"; } || \
        sudo apt-get -y install openssh-client
fi

#-----------------------------------------------------------#



#-----------------------------------------------------------#
# create main project stub

DM_MAIN_DIR="${DM_PROJECT_DIR}/main"
if [ ! -d ${DM_MAIN_DIR} ] && [ -d "${DM_ROOT_DIR}/demo/maintenance" ]; then
    echo -e "${BLUE}Info:${NC} creating main project folder ... ";
    yes 2>/dev/null | sudo cp -rp "${DM_ROOT_DIR}/demo/maintenance" "${DM_MAIN_DIR}"
fi

#-----------------------------------------------------------#



#-----------------------------------------------------------#
# add bash completions for script wrapper

BASH_COMPLETIONS_DIR='/etc/bash_completion.d'
BASH_COMPLETIONS_FILE="${BASH_COMPLETIONS_DIR}/dm"
BASH_COMPLETIONS_SOURCE="${DM_BIN_DIR}/_bash_completions.sh"
if [ -d "${BASH_COMPLETIONS_DIR}" ] && [ ! -L "${BASH_COMPLETIONS_FILE}" ] && [ -f "${BASH_COMPLETIONS_SOURCE}" ]; then
    echo -e "${BLUE}Info:${NC} creating symlink for bash completions ... ";
    sudo ln -s ${BASH_COMPLETIONS_SOURCE} ${BASH_COMPLETIONS_FILE}
fi

#-----------------------------------------------------------#



# finish
echo "";
echo -e "${GREEN}All done.${NC}";
echo -e "${GREEN}Now you${NC} ${YELLOW}should logout${NC} ${GREEN}then${NC} ${YELLOW}after login run \"./dm start\" command${NC} ${GREEN}and then you could see your projects from Docker Manager as${NC} ${YELLOW}http://${DM_HOST_NAME}/${NC} ${GREEN}and sub-domains${NC}";
echo -e "${BLUE}Info: ${NC} to create new project just create unique ${YELLOW}projects/DM_PROJECT/docker-compose.yml${NC} file. For more info visit ${YELLOW}https://github.com/demmonico/docker-manager${NC}";
echo -e "${GREEN}Have a nice day :)${NC}";
echo "";
