#!/usr/bin/env bash
#
# This file has executed each time when container's starts for custom code.
#
# tech-stack: ubuntu / apache / php
# actions: update code by Git and update composer relations
#
# @author demmonico
# @image ubuntu-apache-php
# @version v2.0



### update code
if [ ! -z ${REPOSITORY} ] && [ -d "${PROJECT_DIR}/.git" ]
then
    # update status
    setDummyStatus "Code is updating";
    # update code
    git pull origin ${REPO_BRANCH}
fi



### install composer relations
if [ -f "${PROJECT_DIR}/composer.json" ]
then
    # update status
    setDummyStatus "Composer relations is updating";
    # install
    composer install
fi
