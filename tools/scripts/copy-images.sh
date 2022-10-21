#!/bin/bash

AGG_REGISTRY="registry.aggregion.com"
LOCAL_REGISTRY="localhost:5000"
IMAGES="gatekeeper:1.4.2 \
dmp-frontend:release-22_sep-12d24227-1773 \
dmp-backend:release-22_sep-11f0ec10-1260 \
cron-curl:0.0.1 \
nginx:1.19-alpine \
dmp-seed:latest \
sconecuratedimages/aggregion:las-no-epid-scone-5.6.0 \
enclave-server-signed:2.7.0 \
enclave-external-services:develop \
dataservice:dcp-master-a94b9e16-27 \
atlas-entity-syncer:dcp-master-1bbdc6e7-28 \
curl:latest \
metadata-seed:dcp-master-bfe5f344-30 \
auth-service:dcp-master-f772c8a3-48 \
oidc-provider:dcp-master-ec6eb950-74 \
email-service:dcp-master-a94b9e16-27 \
datalab:latest"

read -ra TAGS <<< "$IMAGES"

for tag in "${TAGS[@]}";
do
  docker pull "$AGG_REGISTRY/$tag"
  docker tag "$AGG_REGISTRY/$tag" "$LOCAL_REGISTRY/$tag"
  docker push "$LOCAL_REGISTRY/$tag"
done
