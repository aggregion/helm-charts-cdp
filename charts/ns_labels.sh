#!/bin/sh -e
# input your company name first argument
# for Example sh '''ns_labels.sh mycompanyname'''
ns="$1"
kubectl create ns $1
kubectl create ns dc
kubectl create ns datalab
kubectl create ns ingress-nginx
kubectl label ns $1 name=$1
kubectl label ns dc name=dc
kubectl label ns datalab name=datalab
kubectl label ns ingress-nginx name=ingress-nginx
kubectl label ns kube-system name=kube-system