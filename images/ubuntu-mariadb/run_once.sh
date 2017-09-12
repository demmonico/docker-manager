#!/bin/bash
# This file has executed after container's builds



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
    #mysql < /schema.sql

    # Tell the MySQL daemon to shutdown.
    mysqladmin shutdown

    # Wait for the MySQL daemon to exit.
    wait $mysql_pid

fi



### run custom script if exists
if [ ! -z ${CUSTOM_SCRIPT_ONCE} ] && [ -f ${CUSTOM_SCRIPT_ONCE} ] && [ -x ${CUSTOM_SCRIPT_ONCE} ]
then
    /bin/bash ${CUSTOM_SCRIPT_ONCE}
fi
