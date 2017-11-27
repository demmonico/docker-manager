#!/bin/bash
#
# This file has executed each time when container's starts
#
# tech-stack: ubuntu / apache / php
#
# @author demmonico
# @image ubuntu-apache-php
# @version v2.0



##### run once
if [ -f "${RUN_ONCE_FLAG}" ]; then
  # run script once
  /bin/bash "${INSTALL_DIR}/run_once.sh"
  # rm flag
  /bin/rm -f ${RUN_ONCE_FLAG}
fi



##### run
cd ${PROJECT_DIR}



### set dummy if defined
PROJECT_DUMMY_DIR="$PROJECT_DIR/dummy"

function setDummyStatus
{
    local msg=$@;
    if [ -n "$msg" ] && [ -d "${DUMMY_DIR}" ]; then
        ( echo "$msg"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    fi;
}

if [ -d "${DUMMY_DIR}" ]; then

    # replace htaccess files
    if [ ! -d "${PROJECT_DUMMY_DIR}" ]; then
        cp -rf ${DUMMY_DIR} ${PROJECT_DUMMY_DIR}
        if [ -f "${PROJECT_DIR}/.htaccess" ]; then
            cp ${PROJECT_DIR}/.htaccess ${PROJECT_DIR}/real.htaccess
        fi
        yes | cp -rf ${DUMMY_DIR}/.htaccess ${PROJECT_DIR}/.htaccess
    fi

    # start apache for dummy
    setDummyStatus "Starting apache";
    service apache2 start
fi



### run custom script if exists
CUSTOM_SCRIPT="${INSTALL_DIR}/custom.sh"
if [ -f ${CUSTOM_SCRIPT} ]; then
    chmod +x ${CUSTOM_SCRIPT} && source ${CUSTOM_SCRIPT}
fi



# wait for db
if [ ! -z "${DB_HOST}" ]
then
    # update status
    setDummyStatus "Wait for db container";
    # wait
    while ! mysqladmin ping -h"${DB_HOST}" --silent; do
        sleep 1
    done
fi



### stop dummy
if [ -d "${DUMMY_DIR}" ]; then

    # stop apache
    setDummyStatus "Starting container";
    service apache2 stop

    # rm dummy
    if [ -f "${PROJECT_DIR}/real.htaccess" ]; then
        yes | cp -rf ${PROJECT_DIR}/real.htaccess ${PROJECT_DIR}/.htaccess
        /bin/rm -f ${PROJECT_DIR}/real.htaccess
    else
        /bin/rm -f ${PROJECT_DIR}/.htaccess
    fi
    /bin/rm -rf ${PROJECT_DUMMY_DIR}
fi



### FIX permissions
chown -R www-data:www-data ${PROJECT_DIR}



### FIX cron start
cron



#### run supervisord
exec /usr/bin/supervisord -n
