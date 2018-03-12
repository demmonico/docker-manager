#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This is wrapper script for bin scripts of Docker Manager
#
# FORMAT:
#   [sudo] ./dm [COMMAND] [OPTIONS] [PARAMS]
#
# COMMANDS:
#   install
#   start
#   stop
#-----------------------------------------------------------#


### root dir
DM_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DM_BIN_DIR="${DM_ROOT_DIR}/bin"
DM_BIN_HELP='BIN_HELP.md'
DM_PARSER='parse_markdown.sh'


### get route
script="$1"
case ${script} in
    -h|-help|--help)
        source "${DM_BIN_DIR}/${DM_PARSER}"
        parse_markdown "${DM_ROOT_DIR}/${DM_BIN_HELP}"
        ;;
    install|start|stop)
        exec ${DM_BIN_DIR}/${script}.sh "${@:2}"
        ;;
    *)
        echo "Invalid option: \"$1\""
        exit 1
        ;;
esac
