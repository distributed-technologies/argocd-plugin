
#!/bin/bash

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
WORK_ADD_RES=${WORK_DIR}/additional_resources

BASE_VALUES_TEMPLATED=${WORK_DIR}/base_VALUES.yaml
ENV_VALUES_TEMPLATED=${WORK_DIR}/env_VALUES.yaml

TEMP_VALUES=${WORK_DIR}/temp_values.yaml
GLOBAL=${WORK_DIR}/global.yaml

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
{
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
    cp ${_TEMPLATES} ./temp/templates/
    cp ${_VALUES} ./temp/values.yaml
    helm template temp
    rm temp -r > /dev/null
  }

  # Make work directory
  mkdir -p ${WORK_DIR}

  # Merge globals
  yaml-merge ${BASE_GLOBAL} ${ENV_GLOBAL} > ${GLOBAL}

  # Template base/values.yaml from globals
  template ${BASE_VALUES} ${GLOBAL} > ${BASE_VALUES_TEMPLATED}

  # Template env/values.yaml from globals
  template ${ENV_VALUES} ${GLOBAL} > ${ENV_VALUES_TEMPLATED}

  # Merge base and env values.yaml, and remove temp files
  yaml-merge ${BASE_VALUES_TEMPLATED} ${ENV_VALUES_TEMPLATED} > ${TEMP_VALUES}
  rm ${BASE_VALUES_TEMPLATED}
  rm ${ENV_VALUES_TEMPLATED}

  # TODO: discuss, This might cause issues and is not required
  # Merge globals and temp_values to the final values.yaml
  yaml-merge ${GLOBAL} ${TEMP_VALUES} > ${VALUES}
  rm ${GLOBAL}
  rm ${TEMP_VALUES}

  # Template the helm chart with the generated values.yaml
  helm template ${ARGOCD_APP_NAME} ${ARGOCD_APP_SOURCE_PATH} \
      --repo ${ARGOCD_APP_SOURCE_REPO_URL}  \
      --namespace ${ARGOCD_APP_NAMESPACE} \
      --version ${ARGOCD_APP_SOURCE_TARGET_REVISION} \
      --values ${VALUES} \
      > ${MANIFEST}

  # Copy extra files into common folder, and template and concat onto manifest
  # TODO: ignore extra files if paths are empty.

  if [[ "$BASE_ADDITIONAL_RESOURCES" ]]; then
    mkdir -p ${WORK_ADD_RES}
    cp -r ${BASE_ADDITIONAL_RESOURCES}/* ${WORK_ADD_RES}
    cp -r ${ENV_ADDITIONAL_RESOURCES}/* ${WORK_ADD_RES}
    template ${WORK_ADD_RES} ${VALUES} >> ${MANIFEST}
  fi
  # Output manifest on STDOUT
  cat ${MANIFEST}
}

# Remove working directory
rm -r ${WORK_DIR}

# TODO create unit test !!!!!!!!!