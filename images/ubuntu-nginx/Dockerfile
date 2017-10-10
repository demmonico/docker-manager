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
    # apache, curl, git
    && apt-get install -y --force-yes  --no-install-recommends nginx curl unzip \
    # configure apache
#    && ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/ \
#    && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \

    # demonisation for docker
    && apt-get install -y supervisor \

    # mc
    && apt-get -qq update && apt-get -qq -y install mc \

    # clear apt etc
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /var/log/supervisor


EXPOSE 80


### UPDATE & RUN PROJECT
COPY supervisord.conf /etc/supervisor/supervisord.conf

COPY run_once.sh /run_once.sh
ENV RUN_ONCE_FLAG "/run_once"
RUN tee ${RUN_ONCE_FLAG} && chmod +x /run_once.sh
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
