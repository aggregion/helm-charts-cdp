#!/bin/sh

helm upgrade --install --create-namespace \
  -n dc \ #not change
  -f dc_values_external.yaml \ #values with helm charts
  dcext \ # not change
  ./aggregion-externals   # path to directory charts
