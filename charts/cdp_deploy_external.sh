#!/bin/sh

helm upgrade --install --create-namespace \ 
  -n alfatravel \ #change "alfatravel" on your namespace
  -f cdp_values_external.yaml \ #values with helm charts
  alfaext \ # name helmcharts
  ./aggregion-externals # path to directory charts
