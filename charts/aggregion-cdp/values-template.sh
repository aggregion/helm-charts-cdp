#!/bin/bash

# echo "" | bash charts/aggregion-cdp/values-template.sh > cdp_local_values_v1.yaml

cd $(dirname $0)

export LC_ALL=C
export TEMPLATE_FILENAME=${TEMPLATE_FILENAME:-values-template.yaml}
export KEYS_ABS_DIR="${KEYS_ABS_DIR:-.}"
export PRIVATE_KEY_FILENAME=private.pem
export PUBLIC_KEY_FILENAME=public.pem
export PRIVATE_KEY_ABS_PATH="$KEYS_ABS_DIR/$PRIVATE_KEY_FILENAME"
export PUBLIC_KEY_ABS_PATH="$KEYS_ABS_DIR/$PUBLIC_KEY_FILENAME"
export CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-cluster.local}"
export URL_SUFFIX="${URL_SUFFIX:--prod}" # delete
export CDP_SUFFIX="${CDP_SUFFIX:--cdp-prod}"
export MONGO_SVC_SUFFIX="${MONGO_SVC_SUFFIX:--externals-prod}"
export RABBIT_SVC_SUFFIX="${RABBIT_SVC_SUFFIX:--externals-prod}"
export REDIS_SVC_SUFFIX="${REDIS_SVC_SUFFIX:--externals-prod}"
export PG_SVC_SUFFIX="${PG_SVC_SUFFIX:--externals-prod}"
export BASE_FRONT_DOMAIN="${BASE_FRONT_DOMAIN:-app.aggregion.com}"
export BASE_FRONT_URL_SCHEMA="${BASE_FRONT_URL_SCHEMA:-http}"
export CDP_NS="${CDP_NS:-agg-prod}"
export DC_NS="${DC_NS:-agg-prod-dc}"
export EOS_WALLET_PUBLIC_KEY="${EOS_WALLET_PUBLIC_KEY:-CHANGEIT}"
export EOS_WALLET_PRIVATE_KEY="${EOS_WALLET_PRIVATE_KEY:-CHANGEIT}"
export ACCOUNT_ID="${ACCOUNT_ID:-CHANGEIT}"
export BACKEND_DATALABPROXY_RESOLVERSERVICEDOMAIN="${BACKEND_DATALABPROXY_RESOLVERSERVICEDOMAIN:-rke2-coredns-rke2-coredns.kube-system.svc}"
export BACKEND_CONFIG_EOSNODEURL="${BACKEND_CONFIG_EOSNODEURL:-http://testnet.blockchain.dmp.aggregion.com:9999}"
export BLOCKCHAIN_COMMON_USERS_CONTRACT="${BLOCKCHAIN_COMMON_USERS_CONTRACT:-dmpusers}"
export BLOCKCHAIN_COMMON_CATALOGS_CONTRACT="${BLOCKCHAIN_COMMON_CATALOGS_CONTRACT:-catalogs}"
export BLOCKCHAIN_COMMON_BASE_CONTRACT="${BLOCKCHAIN_COMMON_BASE_CONTRACT:-aggregion}"
export GATEKEEPER_DCP_CLIENT_SECRET="${GATEKEEPER_DCP_CLIENT_SECRET:-changeit}"
export CDP_DATALAB_PLATFORM_ID="${CDP_DATALAB_PLATFORM_ID:-selectel}"
export CDP_DATALAB_NAMESPACE="${CDP_DATALAB_NAMESPACE:-datalab}"
export CDP_DATALAB_MEMORY_LIMIT_GB="${CDP_DATALAB_MEMORY_LIMIT_GB:-8}"
export GITLAB_SVC_URL="${GITLAB_SVC_URL:-http://gitlab-webservice-default.gitlab.svc.cluster.local:8181#CHANGEIT}"
export GITLAB_TOKEN="${GITLAB_TOKEN:-CHANGEIT}"
export DDM_RELEASE_NAME=ddm
export DDM_POSTFIX=$URL_SUFFIX

export IMAGE_CDP_GK_IMAGE_REPO="${IMAGE_CDP_GK_IMAGE_REPO:-registry.aggregion.com/gatekeeper}"
export IMAGE_CDP_GK_IMAGE_TAG="${IMAGE_CDP_GK_IMAGE_TAG:-1.4.2}"
export IMAGE_CDP_FRONT_IMAGE_REPO="${IMAGE_CDP_FRONT_IMAGE_REPO:-registry.aggregion.com/dmp-frontend}"
export IMAGE_CDP_FRONT_IMAGE_TAG="${IMAGE_CDP_FRONT_IMAGE_TAG:-release-22_sep-47de5668-1889}"
export IMAGE_CDP_BACK_IMAGE_REPO="${IMAGE_CDP_BACK_IMAGE_REPO:-registry.aggregion.com/dmp-backend}"
export IMAGE_CDP_BACK_IMAGE_TAG="${IMAGE_CDP_BACK_IMAGE_TAG:-release-22_sep-906b7f90-1302}"
export IMAGE_CDP_BACK_CROND_IMAGE_REPO="${IMAGE_CDP_BACK_CROND_IMAGE_REPO:-registry.aggregion.com/cron-curl}"
export IMAGE_CDP_BACK_CROND_IMAGE_TAG="${IMAGE_CDP_BACK_CROND_IMAGE_TAG:-0.0.1}"
export IMAGE_CDP_BACK_DATALABPROXY_IMAGE_REPO="${IMAGE_CDP_BACK_DATALABPROXY_IMAGE_REPO:-nginx}"
export IMAGE_CDP_BACK_DATALABPROXY_IMAGE_TAG="${IMAGE_CDP_BACK_DATALABPROXY_IMAGE_TAG:-1.23.3-alpine}"
export IMAGE_CDP_BACK_DBSEED_IMAGE_REPO="${IMAGE_CDP_BACK_DBSEED_IMAGE_REPO:-registry.aggregion.com/dmp-seed}"
export IMAGE_CDP_BACK_DBSEED_IMAGE_TAG="${IMAGE_CDP_BACK_DBSEED_IMAGE_TAG:-latest}"
export IMAGE_CDP_ENCLAVE_SCONE_LAS_IMAGE_REPO="${IMAGE_CDP_ENCLAVE_SCONE_LAS_IMAGE_REPO:-registry.aggregion.com/sconecuratedimages/aggregion}"
export IMAGE_CDP_ENCLAVE_SCONE_LAS_IMAGE_TAG="${IMAGE_CDP_ENCLAVE_SCONE_LAS_IMAGE_TAG:-las-no-epid-scone-5.6.0}"
export IMAGE_CDP_METADATASEED_IMAGE_REPO="${IMAGE_CDP_METADATASEED_IMAGE_REPO:-registry.aggregion.com/metadata-seed}"
export IMAGE_CDP_METADATASEED_IMAGE_TAG="${IMAGE_CDP_METADATASEED_IMAGE_TAG:-dcp-master-b93bfd22-33}"
export IMAGE_CDP_AUTHSERVICE_IMAGE_REPO="${IMAGE_CDP_AUTHSERVICE_IMAGE_REPO:-registry.aggregion.com/auth-service}"
export IMAGE_CDP_AUTHSERVICE_IMAGE_TAG="${IMAGE_CDP_AUTHSERVICE_IMAGE_TAG:-dcp-master-4bb66bb3-51}"
export IMAGE_CDP_OIDCPROVIDER_IMAGE_REPO="${IMAGE_CDP_OIDCPROVIDER_IMAGE_REPO:-registry.aggregion.com/oidc-provider}"
export IMAGE_CDP_OIDCPROVIDER_IMAGE_TAG="${IMAGE_CDP_OIDCPROVIDER_IMAGE_TAG:-dcp-master-4c911744-86}"
export IMAGE_CDP_EMAILSERVICE_IMAGE_REPO="${IMAGE_CDP_EMAILSERVICE_IMAGE_REPO:-registry.aggregion.com/email-service}"
export IMAGE_CDP_EMAILSERVICE_IMAGE_TAG="${IMAGE_CDP_EMAILSERVICE_IMAGE_TAG:-dcp-master-c9cb34e5-29}"
export IMAGE_CDP_CLEOS_IMAGE_REPO="${IMAGE_CDP_CLEOS_IMAGE_REPO:-registry.aggregion.com/cleos}"
export IMAGE_CDP_CLEOS_IMAGE_TAG="${IMAGE_CDP_CLEOS_IMAGE_TAG:-latest}"
export IMAGE_CDP_METADATASERVICE_IMAGE_REPO="${IMAGE_CDP_METADATASERVICE_IMAGE_REPO:-registry.aggregion.com/metadata-service}"
export IMAGE_CDP_METADATASERVICE_IMAGE_TAG="${IMAGE_CDP_METADATASERVICE_IMAGE_TAG:-5f655259}"
export IMAGE_CDP_DBMETADATASYNC_IMAGE_REPO="${IMAGE_CDP_DBMETADATASYNC_IMAGE_REPO:-registry.aggregion.com/db-metadata-sync}"
export IMAGE_CDP_DBMETADATASYNC_IMAGE_TAG="${IMAGE_CDP_DBMETADATASYNC_IMAGE_TAG:-eacd9a51}"
export IMAGE_CDP_DBMETADATASYNCCONSUMER_IMAGE_REPO="${IMAGE_CDP_DBMETADATASYNCCONSUMER_IMAGE_REPO:-registry.aggregion.com/db-metadata-sync-consumer}"
export IMAGE_CDP_DBMETADATASYNCCONSUMER_IMAGE_TAG="${IMAGE_CDP_DBMETADATASYNCCONSUMER_IMAGE_TAG:-b582590f}"
export IMAGE_CDP_AUDIENCEDATASETCONSUMER_IMAGE_REPO="${IMAGE_CDP_AUDIENCEDATASETCONSUMER_IMAGE_REPO:-registry.aggregion.com/audience-dataset-consumer}"
export IMAGE_CDP_AUDIENCEDATASETCONSUMER_IMAGE_TAG="${IMAGE_CDP_AUDIENCEDATASETCONSUMER_IMAGE_TAG:-b582590f}"
export IMAGE_CDP_DDMEVENTCONSUMER_IMAGE_REPO="${IMAGE_CDP_DDMEVENTCONSUMER_IMAGE_REPO:-registry.aggregion.com/ddm-event-consumer}"
export IMAGE_CDP_DDMEVENTCONSUMER_IMAGE_TAG="${IMAGE_CDP_DDMEVENTCONSUMER_IMAGE_TAG:-b582590f}"
export IMAGE_CDP_ENCLAVE_SERVICE_REPO="${IMAGE_CDP_ENCLAVE_SERVICE_REPO:-registry.aggregion.com/enclave-external-services}"
export IMAGE_CDP_ENCLAVE_SERVICE_TAG="${IMAGE_CDP_ENCLAVE_SERVICE_TAG:-latest}"
export IMAGE_CDP_ENCLAVE_SERVER_REPO="${IMAGE_CDP_ENCLAVE_SERVER_REPO:-registry.aggregion.com/enclave-server-nodejs}"
export IMAGE_CDP_ENCLAVE_SERVER_TAG="${IMAGE_CDP_ENCLAVE_SERVER_TAG:-main}"
export IMAGE_CDP_DATASERVICE_API_REPO="${IMAGE_CDP_DATASERVICE_API_REPO:-registry.aggregion.com/dataservice}"
export IMAGE_CDP_DATASERVICE_API_TAG="${IMAGE_CDP_DATASERVICE_API_TAG:-master-989043e9-31}"
export IMAGE_CDP_COMMON_CURL_REPO="${IMAGE_CDP_COMMON_CURL_REPO:-curlimages/curl}"
export IMAGE_CDP_COMMON_CURL_TAG="${IMAGE_CDP_COMMON_CURL_TAG:-7.87.0}"
export IMAGE_CDP_DATASERVICE_JOB_RUNNER_REPO="${IMAGE_CDP_DATASERVICE_JOB_RUNNER_REPO:-curlimages/curl}"
export IMAGE_CDP_DATASERVICE_JOB_RUNNER_TAG="${IMAGE_CDP_DATASERVICE_JOB_RUNNER_TAG:-latest}"

if [[ ! -e $PRIVATE_KEY_ABS_PATH ]];
then
  echo "Generate key pair"
  openssl genrsa -out $PRIVATE_KEY_ABS_PATH 4096
  openssl rsa -in $PRIVATE_KEY_ABS_PATH -outform PEM -pubout -out $PUBLIC_KEY_ABS_PATH
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

OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET=$(echo "$OLD_VALUES" | yq .backend.configs.dmpSecret)
[[ $OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET == 'null' ]] && OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET=
export BACKEND_CONFIGS_DMP_SECRET=${OLD_VALUES_BACKEND_CONFIGS_DMP_SECRET:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY=$(echo "$OLD_VALUES" | yq .gatekeeper.config.encryptionKey)
[[ $OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY == 'null' ]] && OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY=
export GK_CONFIG_ENCRYPTION_KEY=${OLD_VALUES_GK_CONFIG_ENCRYPTION_KEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY=$(echo "$OLD_VALUES" | yq .metadataParams.credentials.encryptionKey)
[[ $OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY == 'null' ]] && OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY=
export MD_PARAMS_CREDS_ENCRYPTION_KEY=${OLD_VALUES_MD_PARAMS_CREDS_ENCRYPTION_KEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

OLD_VALUES_MD_PARAMS_CREDS_IV=$(echo "$OLD_VALUES" | yq .metadataParams.credentials.iv)
[[ $OLD_VALUES_MD_PARAMS_CREDS_IV == 'null' ]] && OLD_VALUES_MD_PARAMS_CREDS_IV=
export MD_PARAMS_CREDS_IV=${OLD_VALUES_MD_PARAMS_CREDS_IV:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)}

OLD_VALUES_DATASERVICE_CONFIG_CREDENTIALSDECRYPTKEY=$(echo "$OLD_VALUES" | yq .dataservice.config.credentialsDecryptKey)
[[ $OLD_VALUES_DATASERVICE_CONFIG_CREDENTIALSDECRYPTKEY == 'null' ]] && OLD_VALUES_DATASERVICE_CONFIG_CREDENTIALSDECRYPTKEY=
export DATASERVICE_CONFIG_CREDENTIALSDECRYPTKEY=${OLD_VALUES_DATASERVICE_CONFIG_CREDENTIALSDECRYPTKEY:-$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)}

export PRIVATE_KEY_6S=$(cat $PRIVATE_KEY_ABS_PATH | sed 's/^/      /')
export PRIVATE_KEY_6S=${PRIVATE_KEY_6S:6}

cat ./$TEMPLATE_FILENAME | envsubst
