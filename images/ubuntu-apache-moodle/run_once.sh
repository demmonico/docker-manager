#!/bin/bash
# This file has executed after container's builds


### set apache user ID equal to host's owner ID
usermod -u ${HOST_USER_ID} www-data && groupmod -g ${HOST_USER_ID} www-data


### install moodle
if [ ! -f "${PROJECT_DIR}/config-dist.php" ]; then
    # clone repo
    git clone ${MOODLE_REPOSITORY} ${PROJECT_DIR}

    # removed because IOMAD hasn't tags - branches only
    # get latest tag if empty
    #if [ -z "${MOODLE_TAG_VERSION}" ]; then MOODLE_TAG_VERSION="$( git describe --tags --abbrev=0 --match v3.* )"; fi && \
    # checkout tag
    #cd ${PROJECT_DIR} && git checkout tags/${MOODLE_TAG_VERSION}

    # checkout version
    cd ${PROJECT_DIR}
    if [ ! -z "${MOODLE_TAG_VERSION}" ]
    then
        git checkout tags/${MOODLE_TAG_VERSION}
    elif [ ! -z "${MOODLE_BRANCH}" ]
    then
        git checkout -b temp origin/${MOODLE_BRANCH}
    fi

    # remove git to prepare
    rm -rf "${PROJECT_DIR}/.git"
fi


### config moodle

# add configs
mv -n /config.php "${PROJECT_DIR}/config.php"

# config db
if [ ! -z "${DB_HOST}" ]
then
    # db host
    sed -i "s/MOODLE_DB_HOST/${DB_HOST}/" "${PROJECT_DIR}/config.php"
    # db name
    if [ -z "${DB_NAME}" ]
    then
        DB_NAME=${PROJECT}
    fi
    sed -i "s/MOODLE_DB_NAME/${DB_NAME}/" "${PROJECT_DIR}/config.php"
fi

# add cron task
USER_NAME=$( getent passwd ${HOST_USER_ID} | cut -d: -f1 )
CRON_LINE_MARKER='\#\#\# begin \# moodle scheduler \#'
CRON_NEW_LINES=$(
    echo '### begin # moodle scheduler #'
    echo '* * * * * /usr/bin/php -f /var/www/html/admin/cli/cron.php > /dev/null 2>&1'
    echo '### end # moodle scheduler #'
)
CRON_LINES=$( crontab -u ${USER_NAME} -l > /dev/null 2>&1 )
( echo ${CRON_LINES} | ( grep -q -F "${CRON_LINE_MARKER}" > /dev/null 2>&1 || echo "${CRON_NEW_LINES}" ) ) | crontab -u ${USER_NAME} -


### run custom script if exists
if [ ! -z ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -f ${CUSTOM_RUN_SCRIPT_ONCE} ] && [ -x ${CUSTOM_RUN_SCRIPT_ONCE} ]
then
    /bin/bash ${CUSTOM_RUN_SCRIPT_ONCE}
fi
