#!/usr/bin/env bash
#-----------------------------------------------------------#
# @author: dep
# @link: https://github.com/demmonico
# @package: https://github.com/demmonico/docker-manager
#
# This script defines contains common used variables
#
#-----------------------------------------------------------#


# set colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


# DM root dir
DM_ROOT_DIR="$(dirname "${DM_BIN_DIR}")"

# DM projects dir
DM_PROJECT_DIR="${DM_ROOT_DIR}/projects"

# DM project/service name splitter (used for docker labels when start/stop containers)
DM_PROJECT_SPLITTER='000'
