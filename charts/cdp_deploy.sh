#!/bin/sh

helm upgrade --install --create-namespace \
  -n betatravel \ #change "betatravel" on your namespace
  -f cdp_values.yaml \ #values with helm charts
  beta \ # name helmcharts
  ./aggregion-cdp #path to directory charts
