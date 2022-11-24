#! /bin/sh

wget http://alfa.dmp.aggregion.com/secret-lhcrypto.yaml
wget http://alfa.dmp.aggregion.com/sc-lhcrypto.yaml

kubectl apply -f secret-lhcrypto.yaml
kubectl apply -f sc-lhcrypto.yaml
