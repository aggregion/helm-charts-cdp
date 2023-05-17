#!/bin/bash

cd $(dirname $0)

export LC_ALL=C

if [[ ! -e ./private.pem ]];
then
  echo "Generate key pair"
  openssl genrsa -out private.pem 4096
  openssl rsa -in private.pem -outform PEM -pubout -out public.pem
fi

OLD_VALUES=$(cat -)

OLD_VALUES_AUTH_SERVICE_JWT_SECRET_KEY=$(echo "$OLD_VALUES" | yq .authservice.config.jwtSecretKey)
[[ $OLD_VALUES_AUTH_SERVICE_JWT_SECRET_KEY == 'null' ]] && OLD_VALUES_AUTH_SERVICE_JWT_SECRET_KEY=
export AUTH_SERVICE_JWT_SECRET_KEY=${OLD_VALUES_AUTH_SERVICE_JWT_SECRET_KEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_MDS_CONFIG_JWT_SECRET=$(echo "$OLD_VALUES" | yq .metadataService.config.jwtSecret)
[[ $OLD_VALUES_MDS_CONFIG_JWT_SECRET == 'null' ]] && OLD_VALUES_MDS_CONFIG_JWT_SECRET=
export MDS_CONFIG_JWT_SECRET=${OLD_VALUES_MDS_CONFIG_JWT_SECRET:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_BACKEND_CONFIGS_JWT_SECRET=$(echo "$OLD_VALUES" | yq .backend.configs.jwtSecret)
[[ $OLD_VALUES_BACKEND_CONFIGS_JWT_SECRET == 'null' ]] && OLD_VALUES_BACKEND_CONFIGS_JWT_SECRET=
export BACKEND_CONFIGS_JWT_SECRET=${OLD_VALUES_BACKEND_CONFIGS_JWT_SECRET:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_DATASERVICE_CONFIG_TOKENSECRETKEY=$(echo "$OLD_VALUES" | yq .dataservice.config.tokenSecretKey)
[[ $OLD_VALUES_DATASERVICE_CONFIG_TOKENSECRETKEY == 'null' ]] && OLD_VALUES_DATASERVICE_CONFIG_TOKENSECRETKEY=
export DATASERVICE_CONFIG_TOKENSECRETKEY=${OLD_VALUES_DATASERVICE_CONFIG_TOKENSECRETKEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_ACCOUNT_ID=$(echo "$OLD_VALUES" | yq .backend.configs.accountName)
[[ $OLD_VALUES_ACCOUNT_ID == 'null' ]] && OLD_VALUES_ACCOUNT_ID=
export ACCOUNT_ID=${OLD_VALUES_ACCOUNT_ID:-CHANGEIT}

OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET=$(echo "$OLD_VALUES" | yq .backend.configs.dmpSecret)
[[ $OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET == 'null' ]] && OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET=
export BACKEND_CONFIGS_DMP_SECRET=${OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY=$(echo "$OLD_VALUES" | yq .gatekeeper.config.encryptionKey)
[[ $OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY == 'null' ]] && OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY=
export GK_CONFIG_ENCRYPTION_KEY=${OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY=$(echo "$OLD_VALUES" | yq .metadataParams.credentials.encryptionKey)
[[ $OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY == 'null' ]] && OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY=
export MD_PARAMS_CREDS_ENCRYPTION_KEY=${OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_MD_PARAMS_CREDS_IV=$(echo "$OLD_VALUES" | yq .metadataParams.credentials.encryptionKey)
[[ $OLD_VALUES_MD_PARAMS_CREDS_IV == 'null' ]] && OLD_VALUES_MD_PARAMS_CREDS_IV=
export MD_PARAMS_CREDS_IV=${OLD_VALUES_MD_PARAMS_CREDS_IV:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)}

export PRIVATE_KEY_6S=$(cat ./private.pem | sed 's/^/      /')
export PRIVATE_KEY_6S=${PRIVATE_KEY_6S:6}

cat ./values-template.yaml | envsubst
