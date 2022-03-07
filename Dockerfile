FROM ubuntu:22.04

RUN apt-get update &&\
    apt-get install curl python3-pip apt-transport-https --yes

RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - &&\
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

RUN apt-get update &&\
    apt-get install helm --yes &&\
    pip3 install yamlpath

USER 999
WORKDIR /plugin

COPY src/plugin.yaml /home/argocd/cmp-server/config/plugin.yaml
COPY src/generate_manifest.sh /usr/bin/generate_manifest
