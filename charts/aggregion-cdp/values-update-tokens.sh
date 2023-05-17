#!/bin/bash

cd $(dirname $0)

VALUES=$(cat -)
TOKENS=$(echo "$VALUES" | bash ../../tools/scripts/tokens/generate-all-tokens.sh)

while read line; do
  VAL_PATH=$(echo "$line" | yq .name)
  OLD_VALUE=$(echo "$VALUES" | yq $VAL_PATH)
  NEW_VALUE=$(echo "$line" | yq .value)
  VALUES="$(echo "$VALUES" | yq "$VAL_PATH |= sub(\"$OLD_VALUE\", \"$NEW_VALUE\")")"
done < <(echo "$TOKENS")

echo "$VALUES"
