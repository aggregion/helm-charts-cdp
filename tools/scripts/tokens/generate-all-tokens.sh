#!/bin/bash

# requirements: https://mikefarah.gitbook.io/yq/
# if you use another version of base64 then you need to set arg `base64 -w 1000000` else just `base64`

cd $(dirname $0)

VALUES=$(cat -)
NOW=$(date +%s)

if [[ $(echo "$VALUES" | yq .kind | grep Application) ]];
then
  VALUES=$(echo "$VALUES" | yq .spec.source.helm.values)
fi;

# echo '----------------'

# MetadataService for DBMetadataSyncer
# echo "MetadataService for DBMetadataSyncer"
METADATA_SERVICE_SECRET="$(echo "$VALUES" | yq '.metadataService.config.jwtSecret' -r)"
METADATA_SERVICE_ISSUER=${METADATA_SERVICE_ISSUER:-aggregion}
METADATA_SERVICE_PAYLOAD=$(cat << EOF
type: ""
service: db-metadata-sync
iat: $NOW
iss: $METADATA_SERVICE_ISSUER
EOF
)
METADATA_SERVICE_PAYLOAD_JSON=$(echo "$METADATA_SERVICE_PAYLOAD" | yq -o j -I 0)
METADATA_SERVICE_TOKEN=$(bash ./token-generator.sh -s "$METADATA_SERVICE_SECRET" -p "$(echo "$METADATA_SERVICE_PAYLOAD_JSON" | base64)")
echo "dataservice.config.metadataServiceToken: $METADATA_SERVICE_TOKEN"
echo "dbMetadataSync.config.metadataServiceToken: $METADATA_SERVICE_TOKEN"

# echo '----------------'
# echo ''

# MetadataService for BackendAPI
# echo "MetadataService for BackendAPI"
METADATA_SERVICE_SECRET="$(echo "$VALUES" | yq '.metadataService.config.jwtSecret' -r)"
METADATA_SERVICE_ISSUER=${METADATA_SERVICE_ISSUER:-aggregion}
METADATA_SERVICE_PAYLOAD=$(cat << EOF
type: ""
service: backend-api
iat: $NOW
iss: $METADATA_SERVICE_ISSUER
EOF
)
METADATA_SERVICE_TOKEN=$(bash ./token-generator.sh -s "$METADATA_SERVICE_SECRET" -p "$(echo "$METADATA_SERVICE_PAYLOAD" | yq -o j -I 0 | base64)")
echo "backend.configs.metadataServiceToken: $METADATA_SERVICE_TOKEN"

# echo '----------------'
# echo ''

# DataService Common
# echo "DataService Common"
DATASERVICE_SERVICE_SECRET="$(echo "$VALUES" | yq '.dataservice.config.tokenSecretKey' -r)"
DATASERVICE_SERVICE_ISSUER="$(echo "$VALUES" | yq '.dataservice.config.tokenIssuer' -r)"
DATASERVICE_SERVICE_PAYLOAD=$(cat << EOF
type: ""
iat: $NOW
iss: $DATASERVICE_SERVICE_ISSUER
EOF
)
DATASERVICE_SERVICE_PAYLOAD_JSON=$(echo "$DATASERVICE_SERVICE_PAYLOAD" | yq -o j -I 0 | base64)
DATASERVICE_SERVICE_TOKEN=$(bash ./token-generator.sh -s "$DATASERVICE_SERVICE_SECRET" -p "$DATASERVICE_SERVICE_PAYLOAD_JSON")
echo "dataservice.config.accessToken: $DATASERVICE_SERVICE_TOKEN"

# echo '----------------'
# echo ''

# DataService for EnclaveServices
# echo "DataService for EnclaveServices"
DATASERVICE_SERVICE_SECRET="$(echo "$VALUES" | yq '.dataservice.config.tokenSecretKey' -r)"
DATASERVICE_SERVICE_ISSUER="$(echo "$VALUES" | yq '.dataservice.config.tokenIssuer' -r)"
DATASERVICE_SERVICE_PAYLOAD=$(cat << EOF
service: enclave
iat: $NOW
iss: $DATASERVICE_SERVICE_ISSUER
EOF
)
DATASERVICE_SERVICE_PAYLOAD_JSON=$(echo "$DATASERVICE_SERVICE_PAYLOAD" | yq -o j -I 0 | base64)
DATASERVICE_SERVICE_TOKEN=$(bash ./token-generator.sh -s "$DATASERVICE_SERVICE_SECRET" -p "$DATASERVICE_SERVICE_PAYLOAD_JSON")
echo "enclave.configs.dataserviceToken: $DATASERVICE_SERVICE_TOKEN";

# echo '----------------'
# echo ''
