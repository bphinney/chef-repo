#!/bin/bash

echo "Usage is:   " $0 "  tenant_file  dbserver database userid password";

if [ -z "$1" ]; then
    echo "no tenant list file provided, exiting";
    exit;
else
        tenant_file=$1; 
fi
if [ -z "$2" ]; then
    echo "no rds host provided, exiting";
    exit;
else
        rds_host="-h"$2;
fi
if [ -z "$3" ]; then
    echo "no databae/schema provided, exiting";
    exit;
else
        database=$3;
fi

if [ ! -z "$4" ]; then
    user="-u"$4;
fi

if [ ! -z "$5" ]; then
    password="-p"$5;
fi

echo "tenant_file: " $tenant_file;
echo "rds_host: " $rds_host;

if [ ! -f $tenant_file ]; then
        echo $tenant_file "does not exist, exiting";
        exit;
fi

results=($(mysql -A $rds_host $user $password  $database  -Bse "select 1;"))
if [ $results -ne 1 ]; then
        echo "unable to connect to mysql using these credentials: mysql -A $rds_host -Bse  "  $results;
        exit;
fi

results=($(mysql -A $rds_host $user $password  $database  -Bse "select count(distinct(datasource_id)) from tenant_config;"))
if [ $results -ne 1 ]; then
        echo "There can be only one datasource_id in tenant_config table, this schema has  "  $results;
        exit;
fi

datasource_id=($(mysql -A $rds_host $user $password  $database  -Bse "select distinct(datasource_id) from tenant_config;"))
if [ ! $datasource_id ]; then
        echo "There is no datasource_id in this schema's tenant_config table  "  $datasource_id;
        exit;
fi
echo "Using datasource_id from this schema's tenant_config table  "  $datasource_id;

OLDIFS=$IFS
IFS=,
while read domainname parentdomainname schoolname communityname; do
        echo "-----------";
        tenant_name=$domainname"."$parentdomainname;
        tenant_schema_name="af_"${domainname//./_};
        echo "School Name: " $schoolname "Tenant Name: " $tenant_name;
        echo "tenant_schema_name :" $tenant_schema_name;

        szBuffer=($(mysql -A $rds_host $user $password  $database  -Bse "select schema_name from tenant_config where tenant_name = \"$tenant_name\" ;"))
        if [ "$tenant_schema_name" == "$szBuffer" ]; then
                echo "fconfig Schema name agrees with tenant_schema_name";
                wSchemaExists=($(mysql -A $rds_host $user $password  $tenant_schema_name  -Bse "select 1;"))
                if [ -z "$wSchemaExists" ]; then
                        echo "$tenant_schema_name does not exist";
                else
                        echo "Ready to add user";
                        insert_new_person=($(mysql -A $rds_host $user $password  $tenant_schema_name  -Bse "INSERT IGNORE INTO person (id,fname,mname,lname,hispanic_latino,birth_date,ref_suffix_id,ref_prefix_id,ref_gender_id,ref_birthcountry_id,ref_birthcity_id,ref_birthstate_id,ref_citizenshipcountry_id,last_updated_by,last_updated_on,created_by,created_on,picture_path,country_id) VALUES (
\"d8276db21c4511e6a70fd7c245128d8b\",\"PrometheanAdministrator\",\"NMI\",\"PrometheanAdministratorUser\",\"0\",NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,\"SYSTEM\",NOW(),\"SYSTEM\",NOW(),NULL,NULL);"));
                        insert_new_user=($(mysql -A $rds_host $user $password  $tenant_schema_name  -Bse "INSERT IGNORE INTO user (id,email,person_id,active,salt,password,activation_timestamp,last_updated_by,last_updated_on,created_by,created_on,username,user_type) VALUES (
\"5c2816c61c4a11e6a70fd7c245128d8b\",NULL,\"d8276db21c4511e6a70fd7c245128d8b\",TRUE,\"[B@5e363baa\",\"ca85f814c39d4b6b3e320c5b9b52b954\",NOW(),\"SYSTEM\",NOW(),\"SYSTEM\",NOW(),\"adminuser\",\"SYSTEM\");"));
                        echo "userid is 'adminuser' password is set to same as 'admin' password (whatever that is)";
                        insert_new_user_role=($(mysql -A $rds_host $user $password  $tenant_schema_name  -Bse "INSERT IGNORE INTO user_role (user_id,role_id) VALUES (\"5c2816c61c4a11e6a70fd7c245128d8b\",\"5b66025ac33e42df98ad258d7b09fdbf\");"));
                        insert_new_user_role=($(mysql -A $rds_host $user $password  $tenant_schema_name  -Bse "INSERT IGNORE INTO user_role (user_id,role_id) VALUES (\"5c2816c61c4a11e6a70fd7c245128d8b\",\"b8576c97dc1f4b58a76ab0eed1c013d3\");"));
                        echo "ADMIN and TEACHER user roles applied"; 
                        echo "       -----------";


                fi
        else
                echo "fconfig Schema name DOES NOT agrees with tenant_schema_name";
        fi

done < $tenant_file;
IFS=$OLDIFS;
