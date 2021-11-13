#!/bin/sh

helm upgrade --install --create-namespace \
  -n dc \ #change "alfatravel" on your namespace
  -f dc_values_external.yaml \ #values with helm charts
  dcext \ # name helmcharts
  ./aggregion-externals   # path to directory charts
