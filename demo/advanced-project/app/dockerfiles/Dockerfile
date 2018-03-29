# Dockerfile for build app container
#
# tech-stack: ubuntu / apache / php
#
# @author demmonico
# @image ubuntu-apache-php
# @version v3.3


FROM demmonico/ubuntu-apache-php:7.0
MAINTAINER demmonico@gmail.com


# copy files to install container
COPY install "${DMC_INSTALL_DIR}/"


# init run script
CMD ["/run.sh"]
