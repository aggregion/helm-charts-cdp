#!/bin/sh

helm upgrade --install --create-namespace \ 
  -n betatravel \ #change "betatravel" on your namespace
  -f cdp_values_external.yaml \ #values with helm charts
  betaext \ # name helmcharts
  ./aggregion-externals # path to directory charts
