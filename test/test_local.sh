#!/bin/bash

docker build . -t helm-overdrive:test > /dev/null

docker run --rm -t --env-file ./test/env_with_add.env --volume /home/martin/source/energinet-datahub/argocd-plugin/test:/home/argocd/test helm-overdrive:test sh -c '/home/argocd/generate_manifest.sh' > res_with_add.yaml
DIFF=$(diff -w res_with_add.yaml test/expected_with_add.yaml) 
if [ "$DIFF" != "" ] 
then
    echo "test with additional ❌"
else
    echo "test with additional ✅"
fi
rm res_with_add.yaml

docker run --rm -t --env-file ./test/env_without_add.env --volume /home/martin/source/energinet-datahub/argocd-plugin/test:/home/argocd/test helm-overdrive:test sh -c '/home/argocd/generate_manifest.sh'> res_without_add.yaml
DIFF=$(diff -w res_without_add.yaml test/expected_without_add.yaml) 
if [ "$DIFF" != "" ] 
then
    echo "test without additional ❌"
else
    echo "test without additional ✅"
fi
rm res_without_add.yaml