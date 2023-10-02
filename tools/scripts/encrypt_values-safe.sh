#!/bin/bash
#
# author: Mandeep Singh Bhabha <mandeep.bhabha@gmail.com>
# Version: 1.0
# Date: 28.09.2023
#

# NOTE: This script generates .sops.yaml in folder, where it is encrypting files. If GLOBAL_PGP_FP is present, it will be used.

# paste global pgp fingerprint here.
### export GLOBAL_PGP_FP=""
SOPS_FILE=".sops.yaml"

DEBUG=0

RED='\033[0;31m'
NC='\033[0m' # No Color
display_usage() {
  echo -e "\nUsage: $0 GPG_KEY <folder> [keep|remove]\n"
  echo -e "GPG_KEY: pgp fingerprint used, if GLOBAL_PGP_FP environment is missing";
  echo -e "This script must be run with following parameters:"
  echo -e "<folder>: folder with yaml files"
  echo -e "remove: remove all unencrypted yaml files"
  echo -e "keep: keep all unencrypted yaml files {default}"
  echo
  echo
  echo -e "GLOBAL_PGP_FP is default."
  echo
  echo -e "${RED}create files with \"-safe.yaml\" suffix for encryption${NC}"
  echo
  echo
  exit 1
}

# if less than two arguments supplied, display usage
if [ $# -lt 2 ]
then
        display_usage
fi
cd $2

if [[ $3 == "" ]]; then
  SECURE=0
fi

if [ "${DEBUG}" = "1" ]; then
  echo "current folder $(pwd)"
  echo $1
  echo $2
  if [[ $3 == "" ]]; then
    echo $SECURE
  else
    echo $3
  fi
fi
if [[ ("$3" == "keep")||("$3" == "") ]]; then
  SECURE=0
else
  SECURE=1
fi

PGP_FP_STR="${GLOBAL_PGP_FP:-$1}"

if [ "${DEBUG}" = "1" ]; then
  echo "Create SOPS files with keys from cli"
fi
# if [[ ! -f "$SOPS_FILE" ]]; then
#   if [ "${DEBUG}" = "1" ]; then
#     echo "sops file missing generating one"
#   fi
  cat >.sops.yaml<<EOF
creation_rules:
- pgp: $PGP_FP_STR
EOF
# fi

if [[ $(ls *-safe.yaml 2>&1)  =~ "No such file or directory" ]]; then
  if [ "${DEBUG}" = "1" ]; then
    echo "No files were available for encryption in folder."
  fi
  exit 1
else
  LISTCOMMAND=$(ls *-safe.yaml)
  # echo $?
fi
if [[ "$SECURE" == 1 ]]; then
  if [ "${DEBUG}" = "1" ]; then
    echo -e "File security is enabled, remove all unencrypted sensitive yaml files."
  fi
else
  if [ "${DEBUG}" = "1" ]; then
    echo -e "${RED}File security is disabled${NC}."
  fi
fi
for filename in $LISTCOMMAND
do
  if [ "${DEBUG}" = "1" ]; then
    echo encrypting file $filename
    echo "helm secrets encrypt ${filename%.*}.${filename##*.} > ${filename%.*}.encrypted.${filename##*.}"
  fi
  helm secrets encrypt ${filename%.*}.${filename##*.} > ${filename%.*}.encrypted.${filename##*.}
  if [[ "$SECURE" == 1 ]]; then
    if [ "${DEBUG}" = "1" ]; then
      echo rm ${filename%.*}.${filename##*.}
    fi
    rm ${filename%.*}.${filename##*.}
  fi
done

if [ "${DEBUG}" = "1" ]; then
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo
  echo "Please use following command to deploy application: "
  echo helm upgrade --install -n NAMESPACE -f secrets://${filename%.*}.encrypted.${filename##*.} -f ${filename%.*}.local.yaml RELEASENAME HELMCHART/
  echo
  echo "To modifiy: "
  echo helm secrets edit ${filename%.*}.encrypted.${filename##*.}

  echo
  echo -e "\t${RED}make sure that helm secrets is installed on jump host${NC}"
  echo "helm plugin install https://github.com/jkroepke/helm-secrets --version v4.5.0"
  echo
  # # Multiple pgp keys example
  #   cat >>.sops.yaml<<EOF
  # creation_rules:
  # - pgp: >-
  #     $GLOBAL_PGP_FP,
  #     $GLOBAL_PGP_FP2
  # EOF
fi
