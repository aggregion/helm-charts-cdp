#! /bin/sh

timestamp=$(date +%Y-%m-%d_%H-%M)
mkdir -p /root/Backup_mongo/bckp`date +%Y-%m-%d_%H-%M` #EDIT YOUR DIRECTORY
pod=$(kubectl get pods -A | grep mongo | awk {'print$2'})
ns=betatravel #EDIT YOUR NAMESPACE
kubectl -n $ns exec -it $pod -- sh -c "mongodump --db=dmp --gzip --archive=/tmp/backup_dmp.gzip"
kubectl -n $ns exec -it $pod -- sh -c "mongodump --db=ds --gzip --archive=/tmp/backup_ds.gzip"
kubectl cp $ns/$pod:/tmp/backup_dmp.gzip /root/Backup_mongo/bckp`date +%Y-%m-%d_%H-%M`/backup_dmp.gzip #EDIT YOUR DIRECTORY
kubectl cp $ns/$pod:/tmp/backup_ds.gzip /root/Backup_mongo/bckp`date +%Y-%m-%d_%H-%M`/backup_ds.gzip #EDIT YOUR DIRECTORY
sleep 60
kubectl -n $ns exec -it $pod -- sh -c "rm -rf /tmp/*.gzip"
