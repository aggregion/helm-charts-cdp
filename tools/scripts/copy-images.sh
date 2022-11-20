#!/bin/bash

AGG_REGISTRY="registry.aggregion.com"
LOCAL_REGISTRY="localhost:5000"
IMAGES="gatekeeper:1.4.2 \
dmp-frontend:release-22_sep-47de5668-1889 \
dmp-backend:release-22_sep-906b7f90-1302 \
cron-curl:0.0.1 \
nginx:1.19-alpine \
dmp-seed:latest \
sconecuratedimages/aggregion:las-no-epid-scone-5.6.0 \
enclave-server-signed:2.10.6 \
enclave-external-services:develop \
dataservice:dcp-master-21a9c484-41 \
atlas-entity-syncer:dcp-master-1bbdc6e7-28 \
curl:latest \
metadata-seed:dcp-master-b93bfd22-33 \
auth-service:dcp-master-4bb66bb3-51 \
oidc-provider:dcp-master-4c911744-86 \
email-service:dcp-master-c9cb34e5-29 \
datalab:latest \
datalab-auth:latest \
pipeline-stopper:b1f9c8f8 \
pipeline-runner:b1f9c8f8 \
pipeline-watcher:b1f9c8f8 \
cleanroom/result-publisher-production:0.7.2 \
cleanroom/python-runner-production:0.5.7 \
cleanroom/dataset-downloader-production:0.8.0 \
cleanroom/scripts-downloader-production:0.7.0 \
tekton/prunner:v0.36.0 \
tekton/webhook:v0.36.0 \
tekton/controller:v0.36.0 \
rancher/pause:3.6 \
trinodb/trino:master-105f5773-18 \
keycloak:dcp-master-e32f1b74-10 \
atlas:1.39.0 \
session-provider:2.6.0 \
perftest/jmeter:master \
perftest/jmeter-perfmon-agent:master \
perftest/jmeter-perfmon-collector:master"

read -ra TAGS <<< "$IMAGES"

for tag in "${TAGS[@]}";
do
  docker pull "$AGG_REGISTRY/$tag"
  docker tag "$AGG_REGISTRY/$tag" "$LOCAL_REGISTRY/$tag"
  docker push "$LOCAL_REGISTRY/$tag"
done
