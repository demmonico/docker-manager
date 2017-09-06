#!/bin/bash

##### run once
if [ -f "${RUN_ONCE_FLAG}" ]; then
  # run script once
  /bin/bash run_once.sh
  # rm flag
  /bin/rm -f ${RUN_ONCE_FLAG}
fi


##### run

### run supervisord
exec /usr/bin/supervisord -n
