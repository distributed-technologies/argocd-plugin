#!/bin/bash
set -e

# # Standard ArgoCD Build Environment variables 
# # https://argo-cd.readthedocs.io/en/stable/user-guide/build-environment/
# ARGOCD_APP_NAME - name of application
# ARGOCD_APP_NAMESPACE - destination application namespace.
# ARGOCD_APP_REVISION - the resolved revision, e.g. f913b6cbf58aa5ae5ca1f8a2b149477aebcbd9d8
# ARGOCD_APP_SOURCE_PATH - the path of the app within the repo
# ARGOCD_APP_SOURCE_REPO_URL the repo's URL
# ARGOCD_APP_SOURCE_TARGET_REVISION - the target revision from the spec, e.g. master.
# KUBE_VERSION - the version of kubernetes
# KUBE_API_VERSIONS = the version of kubernetes API

# # Plugin env variables
# # User configurable
# BASE_EXTRA - 
# BASE_GLOBAL - 
# BASE_VALUES -
# ENV_EXTRA -
# ENV_GLOBAL -
# ENV_VALUES -

# Internal env variables
WORK_DIR=_work
WORK_ADD_RES=${WORK_DIR}/add_res

BASE_VALUES_TEMPLATED=${WORK_DIR}/base_values.yaml
ENV_VALUES_TEMPLATED=${WORK_DIR}/env_values.yaml

TEMP_VALUES=${WORK_DIR}/temp_values.yaml
GLOBAL=${WORK_DIR}/globals.yaml

VALUES=${WORK_DIR}/values.yaml
MANIFEST=${WORK_DIR}/manifest.yaml

if [[ -z "$BASE_GLOBAL" ]]; then
  echo "Must provide BASE_GLOBAL in environment" 1>&2
  exit 1
fi

if [[ -z "$ENV_GLOBAL" ]]; then
  echo "Must provide ENV_GLOBAL in environment" 1>&2
  exit 1
fi

if [[ -z "$BASE_VALUES" ]]; then
  echo "Must provide BASE_VALUES in environment" 1>&2
  exit 1
fi

if [[ -z "$ENV_VALUES" ]]; then
  echo "Must provide ENV_VALUES in environment" 1>&2
  exit 1
fi

# Script start
# TODO: try catch to always remove working directory
function validate {
  local _TEMPLATES=${1:?Must provide an argument}
  
  if [[ -z "$BATCHNUM" ]]; then
    echo "Must provide BATCHNUM in environment" 1>&2
    exit 1
  fi
}


# Takes two variables:
# 1. The folder containing your templates
# 2. Value.yaml file you want to template over
# Writes the output of the template to STDOUT
function template {
  local _TEMPLATES=${1:?Must provide an argument}
  local _VALUES=${2:?Must provide an argument}

  helm create temp > /dev/null
  rm -r ./temp/templates/*
  cp -r ${_TEMPLATES} ./temp/templates/ 2> /dev/null
  cp ${_VALUES} ./temp/values.yaml 2> /dev/null
  helm template temp
  rm temp -r > /dev/null
}

# Make work directory
mkdir -p ${WORK_DIR}

# Merge globals
yaml-merge -S ${BASE_GLOBAL} ${ENV_GLOBAL} > ${GLOBAL}

# Template base/values.yaml from globals
template ${BASE_VALUES} ${GLOBAL} > ${BASE_VALUES_TEMPLATED}

# Template env/values.yaml from globals
if test -f "${ENV_VALUES}"
then
  template ${ENV_VALUES} ${GLOBAL} > ${ENV_VALUES_TEMPLATED}
else
  touch ${ENV_VALUES_TEMPLATED}
fi

# Merge base and env values.yaml, and remove temp files
yaml-merge -S ${BASE_VALUES_TEMPLATED} ${ENV_VALUES_TEMPLATED} > ${TEMP_VALUES}
rm ${BASE_VALUES_TEMPLATED}
rm ${ENV_VALUES_TEMPLATED}

# TODO: discuss, This might cause issues and is not required
# Merge globals and temp_values to the final values.yaml
yaml-merge -S ${GLOBAL} ${TEMP_VALUES} > ${VALUES}
rm ${GLOBAL}
rm ${TEMP_VALUES}

# Template the helm chart with the generated values.yaml
helm template ${ARGOCD_APP_NAME} ${CHART_NAME} \
    --repo ${HELM_REPO}  \
    --namespace ${ARGOCD_APP_NAMESPACE} \
    --version ${CHART_VERSION} \
    --values ${VALUES} \
    > ${MANIFEST}

# Copy extra files into common folder, and template and concat onto manifest
# TODO: ignore extra files if paths are empty.

if [[ "$BASE_ADDITIONAL_RESOURCES" || "$ENV_ADDITIONAL_RESOURCES" ]]; then
  mkdir -p ${WORK_ADD_RES}

  if [[ "$BASE_ADDITIONAL_RESOURCES" ]]; then
    cp -r ${BASE_ADDITIONAL_RESOURCES}/. ${WORK_ADD_RES} 2> /dev/null
  fi

  if [[ "$ENV_ADDITIONAL_RESOURCES" ]]; then
    cp -r ${ENV_ADDITIONAL_RESOURCES}/. ${WORK_ADD_RES} 2> /dev/null
  fi
  template ${WORK_ADD_RES} ${VALUES} >> ${MANIFEST}
fi
# Output manifest on STDOUT
cat ${MANIFEST}

# Remove working directory
rm -r ${WORK_DIR}
