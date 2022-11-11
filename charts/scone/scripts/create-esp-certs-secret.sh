#!/bin/bash

NAMESPACE=$1
CRT_FILE=$2
KEY_FILE=$3
SECRET_NAME=esp-certs-secret

HELP="bash ./create-esp-certs-secret.sh NAMESPACE CRT_FILE KEY_FILE"

if [ -z $NAMESPACE ];
then
  echo "Missed NAMESPACE"
  echo $HELP
  exit 1
fi

if [ -z $CRT_FILE ];
then
  echo "Missed CRT_FILE"
  echo $HELP
  exit 1
fi

if [ -z $KEY_FILE ];
then
  echo "Missed KEY_FILE"
  echo $HELP
  exit 1
fi

kubectl create secret generic $SECRET_NAME \
  --from-file=cas.crt=$CRT_FILE \
  --from-file=cas.key=$KEY_FILE \
  -n $NAMESPACE
