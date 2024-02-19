#!/bin/bash
# If a server name is given in Include_server then the script process only that.
# If Include_Server is given empty, then all the server excluding the exclude_server will be code updated/

ODOO_VER=13.0

GIT_USERNAME=root

INCLUDE_SERVER=()
EXCLUDE_SERVER=(custdemo13-odoo mattest13-odoo)

ODOO_BASE_COMMIT="34fdbf"
ODOO_BASE_ENT_COMMIT="124b79"

ODOO_BASE_URL="https://sodexisteam@github.com/odoo/odoo.git"
ODOO_BASE_ENT_URL="https://sodexisteam@github.com/odoo/enterprise.git"

GITLAB_ODOO_BASE_URL="https://${GIT_USERNAME}@gitlab.sodexis.com/odoo/odoo.git"
GITLAB_ODOO_BASE_ENT_URL="https://${GIT_USERNAME}@gitlab.sodexis.com/odoo/odoo-enterprise.git"

WORKDIR=/root

#==============================================================================

if [[ "$1" == "--quiet" ]]; then Q="--quiet"; fi

VER=$(echo ${ODOO_VER} | cut -d. -f1)
CTNAME=(`docker ps --format "{{.Names}}" -f name=${VER}-odoo`)
if [[ ! -z "$INCLUDE_SERVER" ]]; then CTNAME=(${INCLUDE_SERVER[@]}); fi

if [[ ! -d ${WORKDIR}/${ODOO_VER} ]]; then
  git clone --branch ${ODOO_VER} --origin github $ODOO_BASE_URL ${WORKDIR}/${ODOO_VER}
  cd ${WORKDIR}/${ODOO_VER}
  git remote add gitlab $GITLAB_ODOO_BASE_URL
  git fetch gitlab $Q
else
  cd ${WORKDIR}/${ODOO_VER}
  REMOTE_URL="$(git remote -v | grep "gitlab.sodexis.com" | awk 'NR==1''{print $2}')"
  if ! [[ "$REMOTE_URL" =~ "$GITLAB_ODOO_BASE_URL" ]]; then
    git remote remove gitlab
    git remote add gitlab $GITLAB_ODOO_BASE_URL
  fi
  git fetch gitlab $Q
  git fetch github $Q
fi

if [[ ! -d ${WORKDIR}/${ODOO_VER}-Ent ]]; then
  git clone --branch ${ODOO_VER} --origin github $ODOO_BASE_ENT_URL ${WORKDIR}/${ODOO_VER}-Ent
  cd ${WORKDIR}/${ODOO_VER}-Ent
  git remote add gitlab $GITLAB_ODOO_BASE_ENT_URL
  git fetch gitlab $Q
else
  cd ${WORKDIR}/${ODOO_VER}-Ent
  REMOTE_URL="$(git remote -v | grep "gitlab.sodexis.com" | awk 'NR==1''{print $2}')"
  if ! [[ "$REMOTE_URL" =~ "$GITLAB_ODOO_BASE_ENT_URL" ]]; then
    git remote remove gitlab
    git remote add gitlab $GITLAB_ODOO_BASE_URL
  fi
  git fetch gitlab $Q
  git fetch github $Q
fi

for ((i = 0; i <= ${#CTNAME[@]}; ++i)); do
  if [[ "${EXCLUDE_SERVER[@]}" =~ "${CTNAME[$i]}" ]]; then
    continue
  fi
  BASE_CODE_BRANCH="$(docker exec ${CTNAME[$i]} env | grep BASE_CODE_BRANCH | cut -d'=' -f2)"
  BASE_CODE_ENT_BRANCH="$(docker exec ${CTNAME[$i]} env | grep BASE_CODE_ENT_BRANCH | cut -d'=' -f2)"
   code_merge () {
    echo "Merging github/${1} to ${CTNAME[$i]}"
    echo "======================================"
    cd ${WORKDIR}/${1}
    if [[ ! -z "$BASE_CODE_BRANCH" ]]; then
      if ! git show-ref --quiet refs/heads/${2}; then
        git checkout -b ${2} gitlab/${2} $Q
        if [[ "$(git rev-parse --abbrev-ref HEAD)" != "${2}" ]]; then echo "Merge Cancelled. Unable to checkout branch ${2}"; continue; fi
        echo previous_commit: $(git rev-parse --short HEAD)
        git merge $ODOO_BASE_COMMIT $Q
        git push gitlab ${2} $Q
        echo current_commit: $(git rev-parse --short HEAD)
      else
        if [[ "$(git rev-parse --abbrev-ref HEAD)" != "${2}" ]]; then git checkout "${2}" $Q; fi
        if [[ "$(git rev-parse --abbrev-ref HEAD)" != "${2}" ]]; then echo "Merge Cancelled. Unable to checkout branch ${2}"; continue; fi
        git pull gitlab ${2} --quiet
        echo previous_commit: $(git rev-parse --short HEAD)
        git merge ${ODOO_BASE_ENT_COMMIT} $Q
        git push gitlab ${2} $Q
        echo current_commit: $(git rev-parse --short HEAD)
      fi
    else
      echo "Couldn't get BASE_CODE_BRANCH. Check if Server is running"
    fi
  }

  code_merge "${ODOO_VER}" "${BASE_CODE_BRANCH}" "${ODOO_BASE_COMMIT}"
  code_merge "${ODOO_VER}-Ent" "${BASE_CODE_ENT_BRANCH}" "${ODOO_BASE_ENT_COMMIT}"

done