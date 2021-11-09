#!/bin/sh

helm upgrade --install --create-namespace \
  -n alfatravel \ #change "alfatravel" on your namespace
  -f cdp_values.yaml \ #values with helm charts
  alfa \ # name helmcharts
  ./aggregion-cdp #path to directory charts
