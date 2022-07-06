#!/bin/sh

helm upgrade --install --create-namespace \
  -n betatravel \ #change "betatravel" on your namespace
  -f pipeline_values.yaml \ #values with helm charts
  beta \ # name helmcharts
  ./pipeline #path to directory charts
