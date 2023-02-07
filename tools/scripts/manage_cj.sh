#! /bin/sh
status=$1
input_ns=$2
ns=${input_ns:-betatravel}
cronjob1=$(kubectl get cj -n $ns | grep dataservice | awk {'print$1'}i)
cronjob2=$(kubectl get cj -n $ns | grep metadataseed | awk {'print$1'})

kubectl patch -n $ns cronjobs $cronjob1 -p "{\"spec\" : {\"suspend\" : $status}}"
kubectl patch -n $ns cronjobs $cronjob2 -p "{\"spec\" : {\"suspend\" : $status}}"
