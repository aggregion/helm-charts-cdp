#!/bin/sh
helm upgrade --install --create-namespace \
  -n betatravel \ #change "betatravel" on your namespace
  -f atlas_values.yaml \ #values with helm charts 
  betaatlas \ # name helmcharts
  ./atlas # path to directory charts
