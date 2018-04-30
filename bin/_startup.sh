#!/usr/bin/env bash
#-----------------------------------------------------------#
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# Works with startup application
#
#-----------------------------------------------------------#


add_startup() {
    local CMD=$1
    local BREAK_ON_ERRORS=$2
    local TARGET_CONFIG_FILE='/etc/rc.local'

    local LINE_EXIT='exit 0'
    local LINE=" && ${LINE_EXIT}"
    [ ! -z "${BREAK_ON_ERRORS}" ] && LINE="${LINE} || exit 1"
    LINE="${CMD}${LINE}"

    if [ -f "${TARGET_CONFIG_FILE}" ]; then
        if grep -Fxq "${LINE_EXIT}" "${TARGET_CONFIG_FILE}"; then
            LINE=$( echo ${LINE} | sed 's#\&#\\\&#g' )
            sudo sed -i -E "s#^${LINE_EXIT}\$#${LINE}#g" "${TARGET_CONFIG_FILE}"
            echo 'done'
        else
            echo 'skip'
        fi
    else
        echo 'fail'
    fi
}
