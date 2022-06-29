#! /bin/sh

timestamp=$(date +%Y-%m-%d_%H-%M)
mkdir -p /root/Backup_postgres/bckp`date +%Y-%m-%d_%H-%M`
pod=$(kubectl get pods -A | grep postgres | awk {'print$2'})
ns=betatravel
kubectl -n $ns exec -it $pod -- sh -c "pg_dumpall -U postgres > /tmp/postgres.dump"
kubectl cp $ns/$pod:/tmp/postgres.dump /root/Backup_postgres/bckp`date +%Y-%m-%d_%H-%M`/postgres.dump
sleep 50
kubectl -n $ns exec -it $pod -- sh -c "rm -rf /tmp/*.dump"