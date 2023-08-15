#!/bin/bash

STD_IN=$(</dev/stdin)

DATA=$(
echo "image_before image_after critical high medium low negligible unknown"

for i in $(echo "$STD_IN" | yq '.[]' -j | jq -c);
do
  echo -n "$(echo $i | jq '.before.image' -r) $(echo $i | jq '.after.image' -r)"
  echo -n ' '

  echo -n "$(echo $i | jq '.before.vulnerabilities.critical.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n "/$(echo $i | jq '.after.vulnerabilities.critical.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n ' ';

  echo -n "$(echo $i | jq '.before.vulnerabilities.high.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n "/$(echo $i | jq '.after.vulnerabilities.high.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n ' ';

  echo -n "$(echo $i | jq '.before.vulnerabilities.medium.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n "/$(echo $i | jq '.after.vulnerabilities.medium.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n ' ';

  echo -n "$(echo $i | jq '.before.vulnerabilities.low.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n "/$(echo $i | jq '.after.vulnerabilities.low.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n ' ';

  echo -n "$(echo $i | jq '.before.vulnerabilities.negligible.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n "/$(echo $i | jq '.after.vulnerabilities.negligible.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n ' ';

  echo -n "$(echo $i | jq '.before.vulnerabilities.unknown.count as $count | if $count == null then "0" else $count end' -r)";
  echo -n "/$(echo $i | jq '.after.vulnerabilities.unknown.count as $count | if $count == null then "0" else $count end' -r)";

  echo;
done
)

echo "$DATA" | column -t -s' '
