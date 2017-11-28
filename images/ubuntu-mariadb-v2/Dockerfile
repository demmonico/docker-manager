# Dockerfile for build app container
#
# tech-stack: ubuntu / mariadb
#
# @author demmonico
# @image ubuntu-mariadb
# @version v2.0


FROM ubuntu:14.04
MAINTAINER demmonico@gmail.com


### ENV CONFIG
ENV DEBIAN_FRONTEND noninteractive
RUN locale-gen en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# for mc
ENV TERM xterm

# dafault name of internal DB
ENV DB_NAME=''


### INSTALL SOFTWARE
ARG MARIADB_VER='10.1'
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && apt-get update \

    # curl, zip, unzip
    && apt-get install -y --force-yes  --no-install-recommends curl zip unzip \

    # DB server
    && apt-get install -y software-properties-common \
    && apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
    && add-apt-repository "deb [arch=amd64,i386,ppc64el] http://www.ftp.saix.net/DB/mariadb/repo/${MARIADB_VER}/ubuntu trusty main" \
    && apt-get update \
    && apt-get install -y mariadb-server \
    # configure DB
    && chown -R mysql:mysql /var/lib/mysql \

    # demonisation for docker
    && apt-get install -y supervisor \

    # mc, rsync and other utils
    && apt-get -qq update && apt-get -qq -y install mc rsync htop \

    # clear apt etc
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/mysql \
    && mkdir -p /var/log/supervisor


EXPOSE 3306


### UPDATE & RUN PROJECT

# copy supervisord config file
COPY supervisord.conf /etc/supervisor/supervisord.conf

# copy files to install container (@version v2.0)
ARG INSTALL_DIR="/docker-install"
ENV INSTALL_DIR="${INSTALL_DIR}"
COPY install "${INSTALL_DIR}/"

# config DB
RUN yes | cp -rf "${INSTALL_DIR}/mariadb.cnf" /etc/mysql/my.cnf \
    && chmod 600 /etc/mysql/my.cnf \
    && yes | cp -rf "${INSTALL_DIR}/mariadb-debian.cnf" /etc/mysql/debian.cnf

# init run once flag
ENV RUN_ONCE_FLAG="${INSTALL_DIR}/run_once"
RUN tee "${RUN_ONCE_FLAG}" && chmod +x "${INSTALL_DIR}/run_once.sh"

# run custom run command if defined
ARG CUSTON_RUN_COMMAND
RUN ${CUSTON_RUN_COMMAND:-":"}

# init run script
ARG RUN_SCRIPT="${INSTALL_DIR}/run.sh"
RUN chmod +x "${RUN_SCRIPT}" && if [ ! -z "${INSTALL_DIR}" ]; then ln -s "${RUN_SCRIPT}" /run.sh; fi
CMD ["/run.sh"]
