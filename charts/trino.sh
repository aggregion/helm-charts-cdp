#!/bin/sh

helm upgrade --install --create-namespace \
  -n betatravel \ #change "betatravel" on your namespace
  -f trino_values.yaml \ #values with helm charts
  betatrino \ # name helmcharts
  ./trino # path to directory charts
