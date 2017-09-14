#!/usr/bin/env bash

# run get_vhosts_environment config_file_to_parse subdomain_name [OPTIONAL]
function get_vhosts_environment() {

    # parse hosts config file
    local YAML_CONFIG_FILE=$1
    local YAML_PARSER_FILE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/parse_yaml.sh"
    eval "$(${YAML_PARSER_FILE} ${YAML_CONFIG_FILE} config_)"

    # virtual host environment string as template
    local TEMPLATE=""
    local VAR="{{subdomain}}"

    # compile hosts from config file
    for i in "${config_proxy_hosts[@]}"
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

