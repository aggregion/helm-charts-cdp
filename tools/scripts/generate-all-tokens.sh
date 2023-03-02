#!/bin/bash

cd $(dirname $0)

VALUES_PATH=${1:-"../../charts/aggregion-cdp/values.yaml"}
NOW=$(date +%s)

echo '----------------'

# MetadataService
echo "MetadataService"
METADATA_SERVICE_SECRET="$(cat $VALUES_PATH | yq '.metadataService.config.jwtSecret' -r)"
METADATA_SERVICE_ISSUER=${METADATA_SERVICE_ISSUER:-aggregion}
METADATA_SERVICE_PAYLOAD=$(cat << EOF
type: ""
service: db-metadata-sync
iat: $NOW
iss: $METADATA_SERVICE_ISSUER
EOF
)
METADATA_SERVICE_PAYLOAD_JSON=$(echo "$METADATA_SERVICE_PAYLOAD" | yq -c | base64)
bash ./token-generator.sh -s "$METADATA_SERVICE_SECRET" -p "$METADATA_SERVICE_PAYLOAD_JSON"

echo '----------------'
echo ''

# DataService
echo "DataService"
DATASERVICE_SERVICE_SECRET="$(cat $VALUES_PATH | yq '.dataservice.config.tokenSecretKey' -r)"
DATASERVICE_SERVICE_ISSUER="$(cat $VALUES_PATH | yq '.dataservice.config.tokenIssuer' -r)"
DATASERVICE_SERVICE_PAYLOAD=$(cat << EOF
type: ""
iat: $NOW
iss: $DATASERVICE_SERVICE_ISSUER
EOF
)
DATASERVICE_SERVICE_PAYLOAD_JSON=$(echo "$DATASERVICE_SERVICE_PAYLOAD" | yq -c | base64)
bash ./token-generator.sh -s "$DATASERVICE_SERVICE_SECRET" -p "$DATASERVICE_SERVICE_PAYLOAD_JSON"

echo '----------------'
echo ''
