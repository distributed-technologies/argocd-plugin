# Standard ArgoCD Build Environment variables 
# https://argo-cd.readthedocs.io/en/stable/user-guide/build-environment/
# Name of application.
export ARGOCD_APP_NAME=my-guestbook 

# Destination application namespace.
export ARGOCD_APP_NAMESPACE=my-namespace

# The resolved revision, e.g. f913b6cbf58aa5ae5ca1f8a2b149477aebcbd9d8
export ARGOCD_APP_REVISION=f913b6cbf58aa5ae5ca1f8a2b149477aebcbd9d8

# The path of the app within the repo
export ARGOCD_APP_SOURCE_PATH=guestbook

# The repo's URL
export ARGOCD_APP_SOURCE_REPO_URL=https://cloudnativeapp.github.io/charts/curated/

# The target revision from the spec, e.g. master.
export ARGOCD_APP_SOURCE_TARGET_REVISION=0.2.0

# The version of kubernetes
export KUBE_VERSION=1.21.9

# The version of kubernetes API
# KUBE_API_VERSIONS

export BASE_GLOBAL=test/test_repo/base/globals.yaml
export ENV_GLOBAL=test/test_repo/env/preview/globals.yaml

export BASE_VALUES=test/test_repo/base/applications/guestbook/guestbook_values.yaml
export ENV_VALUES=test/test_repo/env/preview/applications/guestbook/guestbook_values.yaml

manifest1=$(./src/generate_manifest.sh)
exp1=$(cat ./test/expected_without_add.yaml)

if [ "$manifest1" != "$exp1" ]; then
    echo "result not as expected"
    exit 1
fi

export BASE_ADDITIONAL_RESOURCES=test/test_repo/base/applications/guestbook/additional_resources
export ENV_ADDITIONAL_RESOURCES=test/test_repo/env/preview/applications/guestbook/additional_resources

manifest2=$(./src/generate_manifest.sh)
exp2=$(cat ./test/expected_without_add.yaml)

if [ "$manifest2" != "$exp2" ]; then
    echo "result not as expected"
    exit 1
fi
