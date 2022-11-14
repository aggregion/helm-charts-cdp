#!/bin/bash

# ATTENTION: THIS SCRIPT COPIED FROM docs

ARGS=$(kubectl get po -A | grep cdp-cleos | tr -s ' ')

if [ -z $ARGS ];
then
  echo 'Cannot find the pod'
  exit 1
fi

NAMESPACE=$(echo "$ARGS" | cut -d' ' -f1)
POD_NAME=$(echo "$ARGS" | cut -d' ' -f2)

if [ -z $NAMESPACE ];
then
  echo 'Empty NAMESPACE'
  exit 1
fi

if [ -z $POD_NAME ];
then
  echo 'Empty POD_NAME'
  exit 1
fi

kubectl -n $NAMESPACE exec -ti $POD_NAME bash
