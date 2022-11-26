#!/bin/sh

set -e


NS=${NS:=$1}
REALM=${REALM:=$2}

echo >&2 "Getting keycloak private key for namespace $NS and realm $REALM..."

SQL="
select cc.value from component_config cc
                       join component c on cc.component_id = c.id
                       join realm r on r.id = c.realm_id
where r.name='${REALM}' and c.name = 'rsa-generated' and cc.name = 'privateKey';
"

POD_NAME=$(kubectl -n $NS get po -o custom-columns=":metadata.name" | grep keycloak | grep postgresql-0 | head -n 1)

echo >&2 "Found pod: " $POD_NAME

SECRET_NAME=$(kubectl -n $NS get secret -o custom-columns=":metadata.name" | grep keycloak | grep postgresql | head -n 1)

echo >&2 "Found secret: " $SECRET_NAME

PG_PASSWORD=$(kubectl -n $NS get secret $SECRET_NAME -o json | jq '.data."postgres-password"' -r | base64 -d)

echo >&2 "Found pg password: " $PG_PASSWORD


KC_KEY=$(kubectl -n $NS exec -it $POD_NAME -- /bin/sh -c "echo \"${SQL}\" | PGPASSWORD=${PG_PASSWORD} psql --csv -U postgres bitnami_keycloak" | tail -n 1)

echo $KC_KEY
