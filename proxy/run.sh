#!/usr/bin/env bash
#
# This file has executed each time when container's starts
#
# tech-stack: ubuntu / nginx
#
# @author demmonico
# @image proxy
# @version v3.3



##### run once
if [ -f "${DMC_RUN_ONCE_FLAG}" ]; then
  # run script once
  source /run_once.sh
  # rm flag
  /bin/rm -f ${DMC_RUN_ONCE_FLAG}
fi



##### run

### run custom script if exists
CUSTOM_SCRIPT="${DMC_INSTALL_DIR}/custom.sh"
if [ -f ${CUSTOM_SCRIPT} ]; then
    chmod +x ${CUSTOM_SCRIPT} && source ${CUSTOM_SCRIPT}
fi
if [ ! -z "${DMC_CUSTOM_RUN_COMMAND}" ]; then
    eval ${DMC_CUSTOM_RUN_COMMAND}
fi



### FIX cron start
cron



### call jwilder/nginx-proxy entrypoint
exec /app/docker-entrypoint.sh forego start -r
