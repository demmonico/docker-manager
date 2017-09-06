#!/bin/bash


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
cp -rf ${DUMMY_DIR} ${PROJECT_DUMMY_DIR}
if [ -f "${PROJECT_DIR}/.htaccess" ]; then
    cp ${PROJECT_DIR}/.htaccess ${PROJECT_DIR}/real.htaccess
fi
yes | cp -rf ${DUMMY_DIR}/.htaccess ${PROJECT_DIR}/.htaccess

# start apache for dummy
( echo "Starting apache"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
service apache2 start



### update code
( echo "Code is updating"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
git pull origin ${REPO_BRANCH}

# install composer relations
( echo "Composer relations is updating"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
composer install

# setup environment
( echo "Environment is setting up"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
if [ ! -z "$PROJECT_ENV" ]
then
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
    ( echo "Running db migrations"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
    php yii migrate --interactive=0
fi



### stop dummy's apache
( echo "Starting container"; ) | sudo tee ${PROJECT_DUMMY_DIR}/status
service apache2 stop

# rm dummy
if [ -f "${PROJECT_DIR}/real.htaccess" ]; then
    yes | cp -rf ${PROJECT_DIR}/real.htaccess ${PROJECT_DIR}/.htaccess
    /bin/rm -f ${PROJECT_DIR}/real.htaccess
fi
/bin/rm -rf ${PROJECT_DUMMY_DIR}



### run supervisord
exec /usr/bin/supervisord -n
