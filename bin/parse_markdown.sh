#!/usr/bin/env bash
#-----------------------------------------------------------#
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# Helps to parse Markdown files
#
#-----------------------------------------------------------#


parse_markdown() {
    local FILE=$1
    local ESC=$(printf '\033')
    local GREEN="${ESC}[0;32m"
    local YELLOW="${ESC}[1;33m"
    local NC="${ESC}[0m" # No Color

    local TEXT=$(\
        cat "${FILE}" | \
        sed '/^[[:space:]]*$/d' | \
        sed '/^```.*$/d' | \
        sed -E "s/^#{3,}[[:space:]]*(.*)$/\n${YELLOW}\1${NC}/g" | \
        sed -E "s/^(.*\.\/dm.*)$/${GREEN}&${NC}/g" | \
        sed -E "s/^(.*\.\/bin\/.*)$/${GREEN}&${NC}/g"\
    )

    echo -e "${TEXT}"
}
