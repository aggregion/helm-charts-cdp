#!/bin/sh

helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency build


export KUBE_NAMESPACE=keycloak-namespace

# if keycloak already installed - use existing passwords
export POSTGRESQL_PASSWORD=$(kubectl get secret --namespace "$KUBE_NAMESPACE" keyclock-chart-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
export KEYCLOAK_PASSWORD=$(kubectl get secret --namespace "$KUBE_NAMESPACE" keyclock-chart-keycloak -o jsonpath="{.data.admin-password}" | base64 --decode)

# otherwise generete new one
if [ "$POSTGRESQL_PASSWORD" == "" ]
then
export POSTGRESQL_PASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 12)
export KEYCLOAK_PASSWORD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 12)
fi



helm upgrade --install --namespace $KUBE_NAMESPACE keycloak aggregion-keycloak -f aggregion-keycloak/Values.yaml \
  --set auth.adminPassword=${KEYCLOAK_PASSWORD} \
  --set postgresql.postgresqlPassword=$POSTGRESQL_PASSWORD \
  --set ingress.hostname=kc.${DEPLOY_HOSTNAME}