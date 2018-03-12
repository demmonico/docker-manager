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
#   exists at bin/ folder
#   service commands:
#       help                - show all help info
#       help/commands       - show commands list
#       help/commands -s    - show commands list without service commands
#
#-----------------------------------------------------------#


### root dir
DM_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DM_BIN_DIR="${DM_ROOT_DIR}/bin"
DM_BIN_HELP='BIN_HELP.md'
DM_PARSER='_parse_markdown.sh'

### pull allowed commands
DM_BIN_COMMANDS=$( find ${DM_BIN_DIR} -type f ! -name '_*.sh' -exec basename {} .sh ';' | sort )

### get route
script="$1"
case ${script} in

    # show help from markdown
    help)
        # if section were selected then only it will be shown
        section=$2
        source "${DM_BIN_DIR}/${DM_PARSER}"
        parse_markdown "${DM_ROOT_DIR}/${DM_BIN_HELP}" "${section}"
        exit
        ;;

    # show commands list
    help/commands)
        format=$2
        if [ "${format}" == '-s' ]; then
            commands=()
        else
            commands=('help' 'help/commands')
        fi
        # get
        for command in ${DM_BIN_COMMANDS[@]}
        do
            commands+=(${command})
        done
        # sort
        IFS=$'\n' sorted=($(sort <<<"${commands[*]}"))
        unset IFS
        # echo line-by-line
        for command in ${sorted[@]}
        do
            echo ${command}
        done
        exit
        ;;

    # run command dynamically
    *)
        for command in ${DM_BIN_COMMANDS[@]}
        do
            if [ "${script}" == "${command}" ]; then
                exec ${DM_BIN_DIR}/${script}.sh "${@:2}"
                exit
            fi
        done

        # error
        echo "Invalid option: \"$1\""
        exit 1
        ;;
esac
