#!/bin/bash

WEBSITE="http://alfa.dmp.aggregion.com"
URL="$WEBSITE/inventory_$(hostname).txt"
FILE="/tmp/inventory.txt"

# echo $URL

echo "*********">> $FILE
cat /etc/os-release >> $FILE
echo "*********">> $FILE
echo "Hostname" >> $FILE
hostname >> $FILE
echo "***" >> $FILE
uname -a >> $FILE
echo "*********">> $FILE
echo "IP address info" >> $FILE
ip addr sh >> $FILE
echo "*********">> $FILE
echo "Driver info" >> $FILE
lsmod >> $FILE
echo "*********">> $FILE
echo "route info" >> $FILE
route -n  >> $FILE
echo "environment info" >> $FILE
env   >> $FILE

curl -T $FILE --url $URL

rm -rf $FILE