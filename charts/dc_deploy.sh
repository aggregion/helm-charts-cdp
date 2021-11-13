#!/bin/sh

helm upgrade --install --create-namespace \
  -n dc \ #not change
  -f dc_values.yaml \ #values with helm charts
  dc \ #not change
  ./aggregion-dc #path to directory charts
