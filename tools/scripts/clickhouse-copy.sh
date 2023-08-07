#!/bin/bash

if [[ -z $SRC_URL ]];
then
  echo "Environment variable SRC_URL is required"
  exit 1;
fi

if [[ -z $DST_URL ]];
then
  echo "Environment variable DST_URL is required"
  exit 1;
fi

if [[ -z $SRC_DB ]];
then
  echo "Environment variable SRC_URL is required"
  exit 1;
fi

if [[ -z $DST_DB ]];
then
  echo "Environment variable DST_URL is required"
  exit 1;
fi

TIMEOUT_AFTER_INSERT=60

FORMAT=Arrow

SRC_URL="$SRC_URL/?database=$SRC_DB"
DST_URL="$DST_URL/?database=$DST_DB"

src_tables=$(echo "SHOW TABLES" | curl $SRC_URL -d @- -s)
dst_tables=$(echo "SHOW TABLES" | curl $DST_URL -d @- -s)

for table in $src_tables; do
  echo "start $table";

  # --- define SELECT query
  src_select_sql="SELECT%20*%20FROM%20$table%20FORMAT%20$FORMAT";
  echo "$src_select_sql";
  # ---

  # --- define CREATE TABLE query
  get_src_create_table_sql="SHOW CREATE TABLE $table";
  echo $get_src_create_table_sql;
  # ---

  # --- change CREATE TABLE query for cluster mode
  src_create_table_sql=$(echo "$get_src_create_table_sql" | curl $SRC_URL -d @- -s | sed 's/\\n/ /g' | sed "s/$SRC_DB\\./$DST_DB\\./g")
  if [[ ! -z $DST_CLUSTER_NAME ]];
  then
    src_create_table_sql=$(echo "$src_create_table_sql" | sed "s/$DST_DB\\.$table/$DST_DB\\.$table ON CLUSTER $DST_CLUSTER_NAME/g");
    if grep -q 'ENGINE = Memory' <<< "$create_table_result";
    then
      src_create_table_sql=$(echo "$src_create_table_sql" | sed 's/ENGINE = Memory/ENGINE = ReplicatedMergeTree/');
    else
      src_create_table_sql=$(echo "$src_create_table_sql" | sed 's/ENGINE = MergeTree/ENGINE = ReplicatedMergeTree/');
    fi;
  fi;

  echo $src_create_table_sql;
  # ---

  # --- create table
  create_table_result=$(echo "$src_create_table_sql" | curl "$DST_URL" -d @- -s)
  if grep -q '_ALREADY_EXISTS' <<< "$create_table_result";
  then
    echo "Table $table already exists"
    echo "finish $table";
    echo "---";
    continue;
  fi;
  # ---

  # --- check if TABLE is VIEW then need to skeep
  if grep -q 'CREATE VIEW' <<< "$create_table_result";
  then
    echo "This is VIEW"
    echo "finish $table";
    echo "---";
    continue;
  fi;
  # ---

  sleep 11;

  # --- insert into destination table from source table
  curl "$SRC_URL&query=$src_select_sql" -o ./$table.arrow
  curl -i -X POST -T $table.arrow "$DST_URL&query=INSERT%20INTO%20$table%20FORMAT%20$FORMAT"
  rm -f ./$table.arrow
  # ---

  echo "finish $table";
  echo "---";
  echo;

  echo "sleep $TIMEOUT_AFTER_INSERT secs"
  sleep $TIMEOUT_AFTER_INSERT;

  echo "---";
  echo;
done
