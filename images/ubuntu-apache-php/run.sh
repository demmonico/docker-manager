#!/usr/bin/env bash
#
# DEPRECATED
#
# This file has executed each time when container's starts
#
# tech-stack: ubuntu / apache / php
#
# @author demmonico
# @image ubuntu-apache-php
# @version v1.0



##### run once
if [ -f "${RUN_ONCE_FLAG}" ]; then
  # run script once
  /bin/bash run_once.sh
  # rm flag
  /bin/rm -f ${RUN_ONCE_FLAG}
fi



##### run
cd ${PROJECT_DIR}



### set dummy
PROJECT_DUMMY_DIR="$PROJECT_DIR/dummy"
if [ ! -d "${PROJECT_DUMMY_DIR}" ]; then
    cp -rf ${DUMMY_DIR} ${PROJECT_DUMMY_DIR}
    if [ -f "${PROJECT_DIR}/.htaccess" ]; then
        cp ${PROJECT_DIR}/.htaccess ${PROJECT_DIR}/real.htaccess
    fi
    yes | cp -rf ${DUMMY_DIR}/.htaccess ${PROJECT_DIR}/.htaccess
fi

# start apache for dummy
( echo "Starting apache"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
service apache2 start



### update code
if [ ! -z ${REPOSITORY} ] && [ -d "${PROJECT_DIR}/.git" ]
then
    ( echo "Code is updating"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    git pull origin ${REPO_BRANCH}
fi

# install composer relations
if [ -f "${PROJECT_DIR}/composer.json" ]
then
    ( echo "Composer relations is updating"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    composer install
fi

# setup environment
if [ ! -z "$PROJECT_ENV" ] && [ -f "${PROJECT_DIR}/init" ]
then
    ( echo "Environment is setting up"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    php init --env=${PROJECT_ENV} --overwrite=n
fi

# wait for db
if [ ! -z "${DB_HOST}" ]
then
    ( echo "Wait for db container"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    while ! mysqladmin ping -h"${DB_HOST}" --silent; do
        sleep 1
    done

    # run migrations
    if [ -f "${PROJECT_DIR}/yii" ]
    then
        ( echo "Running db migrations"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
        php yii migrate --interactive=0
    fi
fi



### run custom script if exists
if [ ! -z ${CUSTOM_RUN_SCRIPT} ] && [ -f ${CUSTOM_RUN_SCRIPT} ] && [ -x ${CUSTOM_RUN_SCRIPT} ]
then
    ( echo "Running custom script"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    /bin/bash ${CUSTOM_RUN_SCRIPT}
fi



### stop dummy's apache
( echo "Starting container"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
service apache2 stop

# rm dummy
if [ -f "${PROJECT_DIR}/real.htaccess" ]; then
    yes | cp -rf ${PROJECT_DIR}/real.htaccess ${PROJECT_DIR}/.htaccess
    /bin/rm -f ${PROJECT_DIR}/real.htaccess
else
    /bin/rm -f ${PROJECT_DIR}/.htaccess
fi
/bin/rm -rf ${PROJECT_DUMMY_DIR}



# FIX permissions
chown -R www-data:www-data ${PROJECT_DIR}



### FIX cron start
cron



### run supervisord
exec /usr/bin/supervisord -n
