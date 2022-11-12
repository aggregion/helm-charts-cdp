#!/bin/bash

NAMESPACE=$1
KEYTAG_SECRET=$2
GUARD_TOKEN=$3
ADMIN_USERNAME=$4
ADMIN_PASSWORD=$5
SECRET_NAME=esp-creds-secret

HELP="bash ./create-esp-creds-secret.sh NAMESPACE KEYTAG_SECRET GUARD_TOKEN ADMIN_USERNAME ADMIN_PASSWORD"

if [ -z $NAMESPACE ];
then
  echo "Missed NAMESPACE"
  echo $HELP
  exit 1
fi

if [ -z $KEYTAG_SECRET ];
then
  echo "Missed KEYTAG_SECRET"
  echo $HELP
  exit 1
fi

if [ -z $GUARD_TOKEN ];
then
  echo "Missed GUARD_TOKEN"
  echo $HELP
  exit 1
fi

if [ -z $ADMIN_USERNAME ];
then
  echo "Missed ADMIN_USERNAME"
  echo $HELP
  exit 1
fi

if [ -z $ADMIN_PASSWORD ];
then
  echo "Missed ADMIN_PASSWORD"
  echo $HELP
  exit 1
fi

kubectl create secret generic $SECRET_NAME \
  --from-literal=keytag_secret=$KEYTAG_SECRET \
  --from-literal=guard_token=$GUARD_TOKEN \
  --from-literal=admin_username=$ADMIN_USERNAME \
  --from-literal=admin_password=$ADMIN_PASSWORD \
  -n $NAMESPACE
