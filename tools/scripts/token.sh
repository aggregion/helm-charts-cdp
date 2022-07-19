#! /bin/sh
# input your company name first argument
# for Example sh '''ns_labels.sh betatravel'''

ns='$1'
pod=$(kubectl -n $ns get po| grep aggregion-cdp-dataservice | grep -v aesync | awk {'print$1'})

kubectl -n $ns exec -it $pod -- sh -c "node ./src/cli/index.js token gen -i $ns" > token
kubectl -n $ns exec -it $pod -- sh -c "node ./src/cli/index.js token gen -i $ns -s enclave -t enclave" > etoken

echo 'COMMON TOKEN'
cat token | grep 'token:'
echo 'ENCLAVE TOKEN'
cat etoken | grep 'token:'