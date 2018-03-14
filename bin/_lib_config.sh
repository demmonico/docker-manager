#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# Library for work with configs
#
#-----------------------------------------------------------#



# run getConfig configFileNameToParse paramName categoryName
function getConfig() {

    # parse hosts config file
    local PREFIX='config_'
    local YAML_CONFIG_FILE=$1
    local PARAM_NAME=$2
    local CATEGORY_NAME=$3
    local YAML_PARSER_FILE="${DM_BIN_DIR}/_parse_yaml.sh"

    eval "$(${YAML_PARSER_FILE} ${YAML_CONFIG_FILE} ${PREFIX})"

    CATEGORY_NAME=${CATEGORY_NAME:+"${CATEGORY_NAME}_"}
    PARAM_FULL_NAME="${PREFIX}${CATEGORY_NAME}${PARAM_NAME}"
    # tune for array values
    if [ ! -z "${!PARAM_FULL_NAME}" ] && [[ "$(declare -p ${PARAM_FULL_NAME})" =~ "declare -a" ]]; then
        PARAM_FULL_NAME="${PARAM_FULL_NAME}[@]"
        local result=''
        # check for params format (simple list or key-value list)
        local isKeyValueFormat=$([[ "${!PARAM_FULL_NAME}" = *"="* ]] && echo '1')
        if [ -z "${isKeyValueFormat}" ]; then
            result=$( echo "${!PARAM_FULL_NAME}" | sed -E "s/\s/\n/g" )
        else
            result=$( echo "${!PARAM_FULL_NAME}" | sed -E "\$s/\s([A-Za-z0-9/]+)=/\n\1=/g" )
        fi
        echo -e "${result}"
    else
        echo "${!PARAM_FULL_NAME}"
    fi
}



# run getVhostsEnv localConfigFile [subdomainName]
function getVhostsEnv() {

    # parse hosts config file
    local YAML_CONFIG_FILE=$1
    local YAML_PARSER_FILE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/_parse_yaml.sh"
    eval "$(${YAML_PARSER_FILE} ${YAML_CONFIG_FILE} config_)"

    # virtual host environment string as template
    local TEMPLATE=""
    local VAR="{{subdomain}}"

    # compile hosts from config file
    for i in "${config_network_hosts[@]}"
    do
      if [ -z $TEMPLATE ]
      then
        TEMPLATE="${TEMPLATE}VIRTUAL_HOST="
      else
        TEMPLATE="${TEMPLATE},"
      fi
      TEMPLATE="${TEMPLATE}${VAR}$i"
    done

    # replace subdomain name variable if exists
    local REPLACEMENT="$2"
    if [ -z $REPLACEMENT ]
    then
      echo "${TEMPLATE//$VAR/}"
    else
      REPLACEMENT="${REPLACEMENT}."
      echo "${TEMPLATE//$VAR/$REPLACEMENT}"
    fi
}



# run touchVhostEnv baseDir [project]
function touchVhostEnv() {

    local _BASE_DIR_NAME=$1
    local _PROJECT_NAME=$2
    local _ENV_FILE="$( echo ${_BASE_DIR_NAME}${_PROJECT_NAME:+"/${_PROJECT_NAME}"} )/${DM_HOST_ENV_CONFIG}"

    if [ ! -f ${_ENV_FILE} ]; then
        # virtual hosts
        local VIRTUAL_HOST="$(getVhostsEnv "${LOCAL_CONFIG_FILE}" "${_PROJECT_NAME}")"
        if [ -z ${VIRTUAL_HOST} ]; then echo -e "${RED}Error: file ${LOCAL_CONFIG_FILE} with domain settings is absent!${NC}" 1>&2; exit 1; fi
        echo ${VIRTUAL_HOST} > ${_ENV_FILE}
        # project name
        echo "PROJECT=${_PROJECT_NAME:-main}" >> ${_ENV_FILE}
        # script's owner name
        echo "HOST_USER_NAME=${HOST_USER_NAME}" >> ${_ENV_FILE}
        # script's owner ID
        echo "HOST_USER_ID=${HOST_USER_ID}" >> ${_ENV_FILE}
    fi

    # check for virtual hosts accessible at /etc/hosts whether local environment
    if [ "${DM_HOST_PORT}" != "80" ]; then
        if [ -z "${VIRTUAL_HOST}" ]; then
            local VIRTUAL_HOST="$(getVhostsEnv "${LOCAL_CONFIG_FILE}" "${_PROJECT_NAME}")"
        fi
        VIRTUAL_HOST="$( echo "${VIRTUAL_HOST}" | sed 's/VIRTUAL_HOST=//g'  )"
        local VIRTUAL_HOST_STRING="127.0.0.1        ${VIRTUAL_HOST}"
        if ! grep -q "${VIRTUAL_HOST_STRING}" /etc/hosts; then
            echo -e "${BLUE}Info:${NC} it seems that DM running at local env mode and VHOST ${VIRTUAL_HOST} doesn't exists at ${YELLOW}/etc/hosts${NC} file";
            # is need to update?
            read -p "Do you want to automatically update hosts file? Note: will require for SUDO privileges (y/n) ? " choice
            if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
                sudo echo "${VIRTUAL_HOST_STRING}" | sudo tee -a /etc/hosts >/dev/null 2>&1
            fi
        fi
    fi
}
