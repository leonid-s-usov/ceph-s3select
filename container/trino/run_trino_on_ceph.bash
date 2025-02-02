#!/bin/bash

root_dir()
{
  cd $(git rev-parse --show-toplevel)
}

modify_end_point_on_hive_properties()
{
#TODO if ./trino/catalog/hive.properties exist

  [ $# -lt 1 ] && echo type s3-endpoint-url && return
  root_dir
  export S3_ENDPOINT=$1
  cat container/trino/trino/catalog/hive.properties  | awk -v x=${S3_ENDPOINT:-NO_SET} '{if(/hive.s3.endpoint/){print "hive.s3.endpoint="x"\n";} else {print $0;}}' > /tmp/hive.properties
  cp /tmp/hive.properties container/trino/trino/catalog/hive.properties
  cat ./container/trino/hms_trino.yaml | awk -v x=${S3_ENDPOINT:-NOT_SET} '{if(/[ *]- S3_ENDPOINT/){print "\t- S3_ENDPOINT="x"\n";} else {print $0;}}' > /tmp/hms_trino.yaml
  cp /tmp/hms_trino.yaml ./container/trino/hms_trino.yaml
  cd -
}

trino_exec_command()
{
## run SQL statement on trino 
  sudo docker exec -it trino /bin/bash -c "time trino --catalog hive --schema cephs3 --execute \"$@\""
}

boot_trino_hms()
{
  root_dir
  sudo docker compose -f ./container/trino/hms_trino.yaml up -d  
  cd -
}

shutdown_trino_hms()
{
  root_dir
  sudo docker compose -f ./container/trino/hms_trino.yaml down
  cd -
}

trino_create_table()
{
table_name=$1
create_table_comm="create table hive.cephs3.${table_name}(c1 varchar,c2 varchar,c3 varchar,c4 varchar, c5 varchar,c6 varchar,c7 varchar,c8 varchar,c9 varchar,c10 varchar)
 WITH ( external_location = 's3a://hive/warehouse/cephs3/${table_name}/',format = 'TEXTFILE',textfile_field_separator = ',');"
sudo docker exec -it trino /bin/bash -c "trino --catalog hive --schema cephs3 --execute \"${create_table_comm}\""
}

