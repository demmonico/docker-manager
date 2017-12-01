#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# Library for work with configs
#-----------------------------------------------------------#



# run getConfig configFileNameToParse paramName categoryName
function getConfig() {

    # parse hosts config file
    local PREFIX='config_'
    local YAML_CONFIG_FILE=$1
    local PARAM_NAME=$2
    local CATEGORY_NAME=$3
    local YAML_PARSER_FILE="${DM_BIN_DIR}/parse_yaml.sh"

    eval "$(${YAML_PARSER_FILE} ${YAML_CONFIG_FILE} ${PREFIX})"

    CATEGORY_NAME=${CATEGORY_NAME:+"${CATEGORY_NAME}_"}
    PARAM_FULL_NAME="${PREFIX}${CATEGORY_NAME}${PARAM_NAME}"
    # tune for array values
    if [[ "$(declare -p ${PARAM_FULL_NAME})" =~ "declare -a" ]]; then
        PARAM_FULL_NAME="${PARAM_FULL_NAME}[@]"
    fi

    echo "${!PARAM_FULL_NAME}"
}



# run getVhostsEnv localConfigFile [subdomainName]
function getVhostsEnv() {

    # parse hosts config file
    local YAML_CONFIG_FILE=$1
    local YAML_PARSER_FILE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/parse_yaml.sh"
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
    local _EXPORT_FILE="${_BASE_DIR_NAME}/${_PROJECT_NAME}/${DM_HOST_ENV_CONFIG}"

    if [ ! -f ${_EXPORT_FILE} ]; then
        # virtual hosts
        local VIRTUAL_HOST="$(getVhostsEnv "${LOCAL_CONFIG_FILE}" "${_PROJECT_NAME}")"
        if [ -z ${VIRTUAL_HOST} ]; then echo -e "${RED}Error: file ${LOCAL_CONFIG_FILE} with domain settings is absent!${NC}" 1>&2; exit 1; fi
        echo ${VIRTUAL_HOST} > ${_EXPORT_FILE}
        # project name
        echo "PROJECT=${_PROJECT_NAME:-main}" >> ${_EXPORT_FILE}
        # script's owner name
        echo "HOST_USER_NAME=${HOST_USER_NAME}" >> ${_EXPORT_FILE}
        # script's owner ID
        echo "HOST_USER_ID=${HOST_USER_ID}" >> ${_EXPORT_FILE}
    fi
}
