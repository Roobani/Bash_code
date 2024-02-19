#!/bin/bash

ODOO_SH_ORIGIN_NAME=vit-github
GITLAB_ORIGIN_NAME=origin
BRANCH=12.0

SCRIPT_PATH=`pwd`

for repo in `find "${SCRIPT_PATH}" -maxdepth 1 -type d -not -path "${SCRIPT_PATH}"`; do
  echo "==================================="
  echo "Working with $(basename $repo)"
  echo "==================================="
  cd $repo
  git pull ${GITLAB_ORIGIN_NAME} ${BRANCH} && git push 
done