#!/bin/bash
# This file has executed each time when container's starts



##### run once
if [ -f "${RUN_ONCE_FLAG}" ]; then
  # run script once
  /bin/bash run_once.sh
  # rm flag
  /bin/rm -f ${RUN_ONCE_FLAG}
fi



### run custom script if exists
if [ ! -z ${CUSTOM_RUN_SCRIPT} ] && [ -f ${CUSTOM_RUN_SCRIPT} ] && [ -x ${CUSTOM_RUN_SCRIPT} ]
then
    ( echo "Running custom script"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    /bin/bash ${CUSTOM_RUN_SCRIPT}
fi



### run supervisord
exec /usr/bin/supervisord -n
