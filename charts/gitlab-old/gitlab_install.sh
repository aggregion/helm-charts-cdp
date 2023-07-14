#!/bin/sh

cd $(dirname $0)

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm -n gitlab upgrade --install \
  --timeout 600s \
  --set certmanager-issuer.email=ENTET_YOUR_EMAIL@example.com \
  --set certmanager.install=false \
  --set certmanager.installCRDs=false \
  --set gitlab-runner.install=false \
  --set gitlab-runner.runners.privileged=true \
  --set global.edition=ce \
  --set global.hosts.domain=gitlab.local \
  --set global.hosts.externalIP=ENTER_YOUR_IP \
  --set global.hosts.https=false \
  --set global.ingress.class=nginx \
  --set global.kas.enabled=false \
  --set global.shell.port=2222 \
  --set nginx-ingress.enabled=false \
  --set prometheus.install=false \
  gitlab gitlab/gitlab
