#!/bin/bash

NS=$1

pods=$(kubectl -n $NS get po -oyaml | yq -r '.items[].metadata.name')

while IFS= read -r pod; do
  echo "+- Pod: $pod"
  containers=$(kubectl -n $NS get po $pod -oyaml | yq -r '.spec.containers[].name')

  while IFS= read -r container; do
    image=$(kubectl -n $NS get po $pod -oyaml | yq -r ".spec.containers | map(select(.name == \"$container\")) | map(.image)[0]")

    echo "  +- Container: $container"
    echo "    +- Image: $image"
  done <<< "$containers"
  echo "---------------"
  echo ""
done <<< "$pods"
