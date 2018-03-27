# Dockerfile for build main proxy container
#
# tech-stack: ubuntu / nginx
#
# @author demmonico
# @image proxy
# @version v3.3


FROM jwilder/nginx-proxy
MAINTAINER Jason Wilder mail@jasonwilder.com
MAINTAINER demmonico@gmail.com


### ENV CONFIG
ENV DEBIAN_FRONTEND noninteractive

# for mc
ENV TERM xterm

# additional files required to run container
ENV DMC_INSTALL_DIR="/dm-install"



### INSTALL SOFTWARE
RUN apt-get -yqq update \
    && apt-get -yqq install software-properties-common \
    && apt-get -yqq update \

    # apache, curl, zip, unzip, git, sudo
    && apt-get install -yqq --force-yes --no-install-recommends curl zip unzip sudo \

    # mc, rsync and other utils
    && apt-get -yqq install mc rsync htop nano



### UPDATE & RUN PROJECT

# copy nginx conf files
COPY default_location /etc/nginx/vhost.d/default_location
COPY custom.conf /etc/nginx/conf.d/custom.conf
COPY nginx.tmpl /app/nginx.tmpl

# copy and init run_once script
COPY run_once.sh /run_once.sh
ENV DMC_RUN_ONCE_FLAG="/run_once_flag"
RUN tee "${DMC_RUN_ONCE_FLAG}" && chmod +x /run_once.sh

# run custom run command if defined
ARG DMB_CUSTOM_BUILD_COMMAND
RUN ${DMB_CUSTOM_BUILD_COMMAND:-":"}



# clean temporary and unused folders and caches
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# copy and init run script
COPY run.sh /run.sh
RUN chmod +x /run.sh
CMD ["/run.sh"]
