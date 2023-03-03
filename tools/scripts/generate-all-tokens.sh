#!/bin/bash

cd $(dirname $0)

VALUES_PATH=${1:-"../../charts/aggregion-cdp/values.yaml"}
NOW=$(date +%s)

echo '----------------'

# MetadataService for DBMetadataSyncer
echo "MetadataService for DBMetadataSyncer"
METADATA_SERVICE_SECRET="$(cat $VALUES_PATH | yq '.metadataService.config.jwtSecret' -r)"
METADATA_SERVICE_ISSUER=${METADATA_SERVICE_ISSUER:-aggregion}
METADATA_SERVICE_PAYLOAD=$(cat << EOF
type: ""
service: db-metadata-sync
iat: $NOW
iss: $METADATA_SERVICE_ISSUER
EOF
)
bash ./token-generator.sh -s "$METADATA_SERVICE_SECRET" -p "$(echo "$METADATA_SERVICE_PAYLOAD" | yq -c | base64)"

echo '----------------'
echo ''

# MetadataService for BackendAPI
echo "MetadataService for BackendAPI"
METADATA_SERVICE_SECRET="$(cat $VALUES_PATH | yq '.metadataService.config.jwtSecret' -r)"
METADATA_SERVICE_ISSUER=${METADATA_SERVICE_ISSUER:-aggregion}
METADATA_SERVICE_PAYLOAD=$(cat << EOF
type: ""
service: backend-api
iat: $NOW
iss: $METADATA_SERVICE_ISSUER
EOF
)
bash ./token-generator.sh -s "$METADATA_SERVICE_SECRET" -p "$(echo "$METADATA_SERVICE_PAYLOAD" | yq -c | base64)"

echo '----------------'
echo ''

# DataService Common
echo "DataService Common"
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

# DataService for EnclaveServices
echo "DataService for EnclaveServices"
DATASERVICE_SERVICE_SECRET="$(cat $VALUES_PATH | yq '.dataservice.config.tokenSecretKey' -r)"
DATASERVICE_SERVICE_ISSUER="$(cat $VALUES_PATH | yq '.dataservice.config.tokenIssuer' -r)"
DATASERVICE_SERVICE_PAYLOAD=$(cat << EOF
service: enclave
iat: $NOW
iss: $DATASERVICE_SERVICE_ISSUER
EOF
)
DATASERVICE_SERVICE_PAYLOAD_JSON=$(echo "$DATASERVICE_SERVICE_PAYLOAD" | yq -c | base64)
bash ./token-generator.sh -s "$DATASERVICE_SERVICE_SECRET" -p "$DATASERVICE_SERVICE_PAYLOAD_JSON"

echo '----------------'
echo ''

# DataService for BackendAPI
echo "DataService for BackendAPI"
DATASERVICE_SERVICE_SECRET="$(cat $VALUES_PATH | yq '.dataservice.config.tokenSecretKey' -r)"
DATASERVICE_SERVICE_ISSUER="$(cat $VALUES_PATH | yq '.dataservice.config.tokenIssuer' -r)"
DATASERVICE_SERVICE_PAYLOAD=$(cat << EOF
service: backend-api
iat: $NOW
iss: $DATASERVICE_SERVICE_ISSUER
EOF
)
DATASERVICE_SERVICE_PAYLOAD_JSON=$(echo "$DATASERVICE_SERVICE_PAYLOAD" | yq -c | base64)
bash ./token-generator.sh -s "$DATASERVICE_SERVICE_SECRET" -p "$DATASERVICE_SERVICE_PAYLOAD_JSON"

echo '----------------'
echo ''
