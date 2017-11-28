#!/usr/bin/env bash
#
# DEPRECATED
#
# This file has executed after container's builds
#
# tech-stack: ubuntu / mariadb
#
# @author demmonico
# @image ubuntu-mariadb
# @version v1.1



### init DB
if [ ! -d /var/lib/mysql/mysql ]; then

    # set permissions
    chown mysql:mysql /var/lib/mysql

    # init system tables
    mysql_install_db --user=mysql --ldata=/var/lib/mysql/ --basedir=/usr

    # Start the MySQL daemon in the background.
    /usr/sbin/mysqld &
    mysql_pid=$!

    until mysqladmin ping >/dev/null 2>&1; do
      echo -n "."; sleep 0.2
    done

    # Permit root login without password from outside container.
    mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '';"
    mysql -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"

    # create the default database
    mysql -e "CREATE DATABASE ${DB_NAME};"

    # import database from SQL if exists
    FILE_IMPORT="/var/lib/mysql/${DB_NAME}.sql"
    if [ -f ${FILE_IMPORT} ]
    then
        mysql ${DB_NAME} < ${FILE_IMPORT}
    fi

    # Tell the MySQL daemon to shutdown.
    mysqladmin shutdown

    # Wait for the MySQL daemon to exit.
    wait $mysql_pid

fi



### run custom script if exists
CUSTOM_ONCE_SCRIPT="${INSTALL_DIR}/custom_once.sh"
if [ -f ${CUSTOM_ONCE_SCRIPT} ]; then
    chmod +x ${CUSTOM_ONCE_SCRIPT} && source ${CUSTOM_ONCE_SCRIPT}
fi
