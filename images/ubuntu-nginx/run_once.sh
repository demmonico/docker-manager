#!/bin/bash
# This file has executed after container's builds



### run custom script if exists
if [ ! -z ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -f ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -x ${CUSTOM_RUN_SCRIPT_ONCE} ]
then
    /bin/bash ${CUSTOM_RUN_SCRIPT_ONCE}
fi
