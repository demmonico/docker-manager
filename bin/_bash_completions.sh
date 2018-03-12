#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This file implements bash completion for the script's wrapper of Docker Manager
#
# Usage:
# Temporarily you can source this file in you bash by typing: source _bash_completions.sh
# For permanent availability, copy or link this file to /etc/bash_completion.d/
#
#-----------------------------------------------------------#


_dm()
{
    local prefix prev script command
    COMPREPLY=()
    prefix="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    script="${COMP_WORDS[0]}"
    command="${COMP_WORDS[1]}"

    # exit if calling script does not exist
    test -f ${script} || return 0

    # fetch available commands from script's help/commands command
    local commands opt
    if [ "${command}" == 'help' ]; then
        opt='-s'
    fi
    commands="$( ${script} help/commands ${opt} 2> /dev/null )"

    # generate completion suggestions
    COMPREPLY=( $(compgen -W "${commands}" -- ${prefix}) )
    return 0
}


# register completion for the ./dm command
complete -F _dm ./dm dm
