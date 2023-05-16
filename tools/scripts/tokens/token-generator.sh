#!/bin/bash

# if you use another version of base64 then you need to set arg `base64 -w 1000000` else just `base64`

export LC_ALL=C

# Construct the header
ALG=HS256
TYP=JWT
PAYLOAD=""
SECRET=undefined

##### ARGS PARSING
vars=$(getopt p:t:a:s: $*)
eval set -- "$vars"

# extract options and their arguments into variables.
while true; do
    case "$1" in
      -p ) PAYLOAD=$(echo "$2" | base64 -d); shift 2 ;;
      -t ) TYP="$2"; shift 2 ;;
      -a ) ALG="$2"; shift 2 ;;
      -s ) SECRET="$2"; shift 2 ;;
      * ) break ;;
    esac
done
#####

jwt_header=$(echo -n "{\"alg\":\"$ALG\",\"typ\":\"$TYP\"}" | base64 -w 1000000 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//)

# Construct the payload
payload=$(echo -n "$PAYLOAD" | base64 -w 1000000 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//)

# Note, because the secret may have newline, need to reference using form $""
# echo "SECRET: $SECRET"
# echo "PAYLOAD: $PAYLOAD"

# Convert secret to hex (not base64)
hexsecret="$(echo -n "$SECRET" | xxd -p | tr -d '\n')"

# Calculate hmac signature -- note option to pass in the key as hex bytes
hmac_signature=$(echo -n "${jwt_header}.${payload}" | openssl dgst -sha256 -mac HMAC -macopt hexkey:${hexsecret} -binary | base64 -w 1000000 | sed s/\+/-/g | sed 's/\//_/g' | sed -E s/=+$//)

# Create the full token
jwt="${jwt_header}.${payload}.${hmac_signature}"

echo $jwt
