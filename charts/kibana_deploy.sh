#!/bin/sh
helm upgrade --install --create-namespace \
  -n betatravel \ #change "betatravel" on your namespace
  -f kibana_values.yaml \ #values with helm charts 
  betakibana \ # name helmcharts
  ./kibana # path to directory charts
