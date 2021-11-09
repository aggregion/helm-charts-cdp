#!/bin/sh

helm upgrade --install --create-namespace \
  -n alfatravel \ #change "alfatravel" on your namespace
  -f trino_values.yaml \ #values with helm charts
  alfatrino \ # name helmcharts
  ./trino # path to directory charts
