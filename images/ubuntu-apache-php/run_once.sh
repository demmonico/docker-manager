#!/bin/bash

### init git if we need it
if [ ! -d "${PROJECT_DIR}/.git" ]; then
  cd ${PROJECT_DIR} && git init && git remote add origin ${REPOSITORY} && git pull origin ${REPO_BRANCH}
fi
