#!/bin/bash
#
# author: Mandeep Singh Bhabha <mandeep.bhabha@gmail.com>
# Version: 1.0
# Date: 14.11.2022
#

#DEBUG=true;
DEBUG=false;

display_usage() { 	
  echo -e "\nUsage: $0 [deploy|sts] [start|stop]\n" 
  echo -e "This script must be run with following parameters:" 
  echo -e "deploy: For managing deployments" 
  echo -e "sts: For managing statefulsets" 
  echo -e "Valid action: start/stop" 
  exit 1    
}

# if less than two arguments supplied, display usage 
if [ $# -lt 2 ] 
then 
	display_usage
fi 

TYPE=$1;
ACTION=$( echo $2|awk '{print toupper($0)}')

case $ACTION in
  START) 
    if $DEBUG ; then echo $ACTION process begin; fi ;;
  STOP)  
    if $DEBUG ; then echo $ACTION process begin; fi;;
  *) 
    if $DEBUG ; then 
      echo "$ACTION is not a valid argument!" 
    fi
    display_usage
    ;;
esac

TEMP_FILE1="/var/tmp/pod_data.txt";
ns_array=("NAMESPACE" "kube-system" "kube-node-lease" "kube-public" "local-path-storage" "monitoring" "logs" "ingress-nginx" "default" )  
if [ $ACTION == "STOP" ]; then          
  if $DEBUG ; then echo -e "$ACTION executed on $TYPE\n"; echo -e "saving current running data"; fi
  kubectl get $TYPE -A |awk -F" " '{ print $1,$2,$3 }' > $TEMP_FILE1
fi

if $DEBUG ; then 
  echo -e "DRY RUN commands, no action on cluster\n"
  echo $ACTION action on $TYPE type; 
fi
while read -r namespace pod replica; do 
  if [[ ! " ${ns_array[*]} " =~ " ${namespace} " ]]; then
    if $DEBUG ; then 
      echo "~ ~ ~ ~ ";
      echo "namespace=$namespace pod=$pod";        
    fi                
    if [ $ACTION == "STOP" ]; then          
      if $DEBUG ; then
        echo kubectl scale $TYPE $pod -n $namespace --replicas=0;
      else        
        kubectl scale $TYPE $pod -n $namespace --replicas=0
      fi
    fi
    if [ $ACTION == "START" ]; then
      if $DEBUG ; then                 
        echo kubectl scale $TYPE $pod -n $namespace --replicas=${replica#*/};
      else
        kubectl scale $TYPE $pod -n $namespace --replicas=${replica#*/}
      fi
    fi
  fi
done < $TEMP_FILE1

exit 0
