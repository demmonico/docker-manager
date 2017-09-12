#!/bin/bash
# This file has executed each time when container's starts



##### run once
if [ -f "${RUN_ONCE_FLAG}" ]; then
  # run script once
  /bin/bash run_once.sh
  # rm flag
  /bin/rm -f ${RUN_ONCE_FLAG}
fi



##### run

### run custom script if exists
if [ ! -z ${CUSTOM_SCRIPT} ] && [ -f ${CUSTOM_SCRIPT} ] && [ -x ${CUSTOM_SCRIPT} ]
then
    /bin/bash ${CUSTOM_SCRIPT}
fi

### run supervisord
exec /usr/bin/supervisord -n
