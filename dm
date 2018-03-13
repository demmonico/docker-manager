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


DM_DISPLAY_NAME='Docker Manager'
DM_DISPLAY_URL='https://github.com/demmonico/docker-manager'

YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NC="\033[0m" # No Color

DM_CHANGELOG='CHANGELOG.md'
DM_BIN_HELP='BIN_HELP.md'
DM_PARSER='_parse_markdown.sh'


### root dir
DM_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DM_BIN_DIR="${DM_ROOT_DIR}/bin"

### pull allowed commands
DM_BIN_COMMANDS=$( find ${DM_BIN_DIR} -type f ! -name '_*.sh' -exec basename {} .sh ';' | sort )

### get route
script="$1"
case ${script} in

    # show version
    version)
        version=$(\
            head -n 1 "${DM_CHANGELOG}" | \
            sed -E "s/^#*[[:space:]]*(.*)$/\1/g" \
        )
        echo -e "${YELLOW}${DM_DISPLAY_NAME}${NC} v${version}"
        echo -e "${GREEN}${DM_DISPLAY_URL}${NC}"
        exit
        ;;

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
            # needs for completion
            commands=('help' 'help/commands' 'version')
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
