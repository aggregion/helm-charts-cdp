#!/bin/sh
helm upgrade --install --create-namespace \
  -n datalab \ 
  -f pypisrv_values.yaml \ #values with helm charts 
  pypisrv \ # name helmcharts
  ./aggregion-pypiserver # path to directory charts