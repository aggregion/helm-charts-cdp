#!/bin/bash

cd $(dirname $0)

IMAGES_INFO=$(</dev/stdin)
IMAGES=$(echo "$IMAGES_INFO" | yq '.[].name')
# echo "$IMAGES"
for i in $IMAGES; do
  ITEM=$(echo "$IMAGES_INFO" | yq ".[] | select(.name == \"$i\")")
  IMAGE_BEFORE=$(echo "$ITEM" | yq ".before.image")
  IMAGE_AFTER=$(echo "$ITEM" | yq ".after.image")

  echo "- name: $i"

  # BEFORE
  echo "  before:"
  echo "    image: $IMAGE_BEFORE"
  REPORT_BEFORE=$(grype $IMAGE_BEFORE -o json -q)
  #echo "$REPORT_BEFORE"
  #TYPES=$(echo "$REPORT_BEFORE" | jq '.matches[].vulnerability.severity' -r | sort -u)

  echo "    vulnerabilities:"

  BEFORE_VUL_CRITICAL=$(echo "$REPORT_BEFORE" | jq '[ .matches[].vulnerability | select(.severity == "Critical") ]')
  echo "      critical:"
  echo "        count: $(echo "$BEFORE_VUL_CRITICAL" | jq '. | length')"

  BEFORE_VUL_HIGH=$(echo "$REPORT_BEFORE" | jq '[ .matches[].vulnerability | select(.severity == "High") ]')
  echo "      high:"
  echo "        count: $(echo "$BEFORE_VUL_HIGH" | jq '. | length')"

  BEFORE_VUL_MEDIUM=$(echo "$REPORT_BEFORE" | jq '[ .matches[].vulnerability | select(.severity == "Medium") ]')
  echo "      medium:"
  echo "        count: $(echo "$BEFORE_VUL_MEDIUM" | jq '. | length')"

  BEFORE_VUL_LOW=$(echo "$REPORT_BEFORE" | jq '[ .matches[].vulnerability | select(.severity == "Low") ]')
  echo "      low:"
  echo "        count: $(echo "$BEFORE_VUL_LOW" | jq '. | length')"

  BEFORE_VUL_NEGLIGIBLE=$(echo "$REPORT_BEFORE" | jq '[ .matches[].vulnerability | select(.severity == "Negligible") ]')
  echo "      negligible:"
  echo "        count: $(echo "$BEFORE_VUL_NEGLIGIBLE" | jq '. | length')"

  BEFORE_VUL_UNKNOWN=$(echo "$REPORT_BEFORE" | jq '[ .matches[].vulnerability | select(.severity == "Unknown") ]')
  echo "      unknown:"
  echo "        count: $(echo "$BEFORE_VUL_UNKNOWN" | jq '. | length')"

  # AFTER
  echo "  after:"
  echo "    image: $IMAGE_AFTER"
  REPORT_AFTER=$(grype $IMAGE_AFTER -o json -q)

  echo "    vulnerabilities:"

  AFTER_VUL_CRITICAL=$(echo "$REPORT_AFTER" | jq '[ .matches[].vulnerability | select(.severity == "Critical") ]')
  echo "      critical:"
  echo "        count: $(echo "$AFTER_VUL_CRITICAL" | jq '. | length')"

  AFTER_VUL_HIGH=$(echo "$REPORT_AFTER" | jq '[ .matches[].vulnerability | select(.severity == "High") ]')
  echo "      high:"
  echo "        count: $(echo "$AFTER_VUL_HIGH" | jq '. | length')"

  AFTER_VUL_MEDIUM=$(echo "$REPORT_AFTER" | jq '[ .matches[].vulnerability | select(.severity == "Medium") ]')
  echo "      medium:"
  echo "        count: $(echo "$AFTER_VUL_MEDIUM" | jq '. | length')"

  AFTER_VUL_LOW=$(echo "$REPORT_AFTER" | jq '[ .matches[].vulnerability | select(.severity == "Low") ]')
  echo "      low:"
  echo "        count: $(echo "$AFTER_VUL_LOW" | jq '. | length')"

  AFTER_VUL_NEGLIGIBLE=$(echo "$REPORT_AFTER" | jq '[ .matches[].vulnerability | select(.severity == "Negligible") ]')
  echo "      negligible:"
  echo "        count: $(echo "$AFTER_VUL_NEGLIGIBLE" | jq '. | length')"

  AFTER_VUL_UNKNOWN=$(echo "$REPORT_AFTER" | jq '[ .matches[].vulnerability | select(.severity == "Unknown") ]')
  echo "      unknown:"
  echo "        count: $(echo "$AFTER_VUL_UNKNOWN" | jq '. | length')"
done
