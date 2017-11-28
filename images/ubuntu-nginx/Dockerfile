# DEPRECATED
#
# Dockerfile for build app container
#
# tech-stack: ubuntu / nginx
#
# @author demmonico
# @image ubuntu-nginx
# @version v1.1


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

    # nginx, curl, zip, unzip
    && apt-get install -y --force-yes  --no-install-recommends nginx curl zip unzip \

    # demonisation for docker
    && apt-get install -y supervisor \

    # mc, rsync and other utils
    && apt-get -qq update && apt-get -qq -y install mc rsync htop \

    # clear apt etc
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /var/log/supervisor


EXPOSE 80


### UPDATE & RUN PROJECT

# copy supervisord config file
COPY supervisord.conf /etc/supervisor/supervisord.conf

# init run once flag
COPY run_once.sh /run_once.sh
ENV RUN_ONCE_FLAG "/run_once"
RUN tee ${RUN_ONCE_FLAG} && chmod +x /run_once.sh

# init run script
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
