#!/bin/sh
helm upgrade --install --create-namespace \
  -n alfatravel \ #change "alfatravel" on your namespace
  -f atlas_values.yaml \ #values with helm charts 
  alfaatlas \ # name helmcharts
  ./atlas # path to directory charts
