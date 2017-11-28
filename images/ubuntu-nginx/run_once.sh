#!/usr/bin/env bash
#
# DEPRECATED
#
# This file has executed after container's builds
#
# tech-stack: ubuntu / nginx
#
# @author demmonico
# @image ubuntu-nginx
# @version v1.1



### set apache user ID equal to host's owner ID
usermod -u ${HOST_USER_ID} www-data && groupmod -g ${HOST_USER_ID} www-data



### init git if we need it
if [ ! -d "${PROJECT_DIR}/.git" ] && [ ! -z ${REPOSITORY} ]
then
  cd ${PROJECT_DIR} && git init && git remote add origin ${REPOSITORY} && git pull origin ${REPO_BRANCH}
fi



### run custom script if exists
if [ ! -z ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -f ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -x ${CUSTOM_RUN_SCRIPT_ONCE} ]
then
    /bin/bash ${CUSTOM_RUN_SCRIPT_ONCE}
fi
