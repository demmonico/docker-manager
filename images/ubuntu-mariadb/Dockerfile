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
RUN apt-get update \
    && apt-get -y install software-properties-common \
    && apt-get update \
    # curl, unzip
    && apt-get install -y --force-yes  --no-install-recommends curl unzip \
    # DB
    mariadb-server mariadb-client  \
    # configure DB
    && chown -R mysql:mysql /var/lib/mysql \

    # demonisation for docker
    && apt-get install -y supervisor \

    # mc
    && apt-get -qq update && apt-get -qq -y install mc \

    # clear apt etc
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/mysql \
    && mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor


# config DB
COPY mariadb.cnf /etc/mysql/my.cnf
RUN chmod 600 /etc/mysql/my.cnf
COPY mariadb-debian.cnf /etc/mysql/debian.cnf

EXPOSE 3306


### RUN
COPY supervisord.conf /etc/supervisor/supervisord.conf
CMD /usr/bin/supervisord
