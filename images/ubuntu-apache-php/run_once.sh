#!/bin/bash
# This file has executed after container's builds



### init git if we need it
if [ ! -d "${PROJECT_DIR}/.git" ]; then
  cd ${PROJECT_DIR} && git init && git remote add origin ${REPOSITORY} && git pull origin ${REPO_BRANCH}
fi



### run custom script if exists
if [ ! -z ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -f ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -x ${CUSTOM_RUN_SCRIPT_ONCE} ]
then
    /bin/bash ${CUSTOM_RUN_SCRIPT_ONCE}
fi
