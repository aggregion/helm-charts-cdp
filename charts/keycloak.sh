#!/bin/sh

#helm dependency build ./keycloak19

cd $(dirname $0)

export DEPLOY_HOSTNAME=kc.example.domain.ltd
export KUBE_NAMESPACE=keycloak-namespace

# if keycloak already installed - use existing passwords
export POSTGRESQL_PASSWORD=$(kubectl get secret --namespace "$KUBE_NAMESPACE" keycloak-chart-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
export KEYCLOAK_PASSWORD=$(kubectl get secret --namespace "$KUBE_NAMESPACE" keycloak-chart-keycloak -o jsonpath="{.data.admin-password}" | base64 --decode)

# otherwise generete new one
if [ "$POSTGRESQL_PASSWORD" == "" ]
then
export POSTGRESQL_PASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 12)
export KEYCLOAK_PASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 12)
fi


helm upgrade --install --create-namespace --namespace $KUBE_NAMESPACE \
  --set keycloak.enabled=true \
  --set auth.adminPassword=${KEYCLOAK_PASSWORD} \
  --set global.postgresql.auth.postgresPassword=${POSTGRESQL_PASSWORD} \
  --set ingress.hostname=${DEPLOY_HOSTNAME} \
  --set ingress.enabled=true \
  --set ingress.annotations."kubernetes.io/ingress.class"=nginx \
  --set "extraEnvVars[0].name=KEYCLOAK_PRODUCTION" \
  --set "extraEnvVars[0].value=\"true\"" \
  --set "extraEnvVars[1].name=KEYCLOAK_LOG_OUTPUT" \
  --set "extraEnvVars[1].value=json" \
  --set "extraEnvVars[2].name=KEYCLOAK_LOG_LEVEL" \
  --set "extraEnvVars[2].value=DEBUG" \
  --set "extraEnvVars[3].name=KEYCLOAK_EXTRA_ARGS" \
  --set "extraEnvVars[3].value=\"--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true\"" \
  keycloak ./keycloak19
