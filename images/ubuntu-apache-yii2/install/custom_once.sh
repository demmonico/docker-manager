#!/usr/bin/env bash
#
# This file has executed after container's builds for custom code
#
# tech-stack: ubuntu / apache / php / Yii
# actions: install update Moodle, config, add cron tasks
#
# @author demmonico
# @image ubuntu-apache-yii
# @version v2.0



### Yii2 requires
composer global require "fxp/composer-asset-plugin:^1.2.0"
