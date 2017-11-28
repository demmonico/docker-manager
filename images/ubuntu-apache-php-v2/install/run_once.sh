#!/usr/bin/env bash
#
# This file has executed after container's builds
#
# tech-stack: ubuntu / apache / php
#
# @author demmonico
# @image ubuntu-apache-php
# @version v2.0



### set apache user ID equal to host's owner ID
usermod -u ${HOST_USER_ID} www-data && groupmod -g ${HOST_USER_ID} www-data



### run custom script if exists
CUSTOM_ONCE_SCRIPT="${INSTALL_DIR}/custom_once.sh"
if [ -f ${CUSTOM_ONCE_SCRIPT} ]; then
    chmod +x ${CUSTOM_ONCE_SCRIPT} && source ${CUSTOM_ONCE_SCRIPT}
fi
