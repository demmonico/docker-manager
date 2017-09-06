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


### INSTALL SOFTWARE
ARG MARIADB_VER='10.1'
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && apt-get update \
    # curl, unzip
    && apt-get install -y --force-yes  --no-install-recommends curl unzip \
    # DB
    && apt-get install -y software-properties-common \
    && apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db \
    && add-apt-repository "deb [arch=amd64,i386,ppc64el] http://www.ftp.saix.net/DB/mariadb/repo/${MARIADB_VER}/ubuntu trusty main" \
    && apt-get update \
    && apt-get install -y mariadb-server \
    # configure DB
    && chown -R mysql:mysql /var/lib/mysql \

    # demonisation for docker
    && apt-get install -y supervisor \

    # mc
    && apt-get -qq update && apt-get -qq -y install mc \

    # clear apt etc
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/mysql \
    && mkdir -p /var/log/supervisor


# config DB
COPY mariadb.cnf /etc/mysql/my.cnf
RUN chmod 600 /etc/mysql/my.cnf
COPY mariadb-debian.cnf /etc/mysql/debian.cnf

EXPOSE 3306


### RUN
COPY supervisord.conf /etc/supervisor/supervisord.conf


COPY run_once.sh /run_once.sh
ENV RUN_ONCE_FLAG "/run_once"
RUN tee ${RUN_ONCE_FLAG} && chmod +x /run_once.sh
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]