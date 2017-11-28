#!/usr/bin/env bash
#
# DEPRECATED
#
# This file has executed each time when container's starts
#
# tech-stack: ubuntu / mariadb
#
# @author demmonico
# @image ubuntu-mariadb
# @version v1.1



# define DB_NAME
if [ -z "${DB_NAME}" ]; then
  DB_NAME=${PROJECT}
fi


##### run once
if [ -f "${RUN_ONCE_FLAG}" ]; then
  # run script once
  /bin/bash "${INSTALL_DIR}/run_once.sh"
  # rm flag
  /bin/rm -f ${RUN_ONCE_FLAG}
fi



##### run

### run custom script if exists
CUSTOM_SCRIPT="${INSTALL_DIR}/custom.sh"
if [ -f ${CUSTOM_SCRIPT} ]; then
    chmod +x ${CUSTOM_SCRIPT} && source ${CUSTOM_SCRIPT}
fi

### run supervisord
exec /usr/bin/supervisord -n
