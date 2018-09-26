#!/bin/bash

echo "Usage is:   " $0 "  tenant_file feature_file dbserver database userid password";

tenant_file=$1;
feature_file=$2;

database=$4;
if [ -z "$1" ]; then
    echo "no tenant list file provided, exiting";
    exit;
fi
if [ -z "$2" ]; then
    echo "no feature list file provided, exiting";
    exit;
fi
if [ -z "$3" ]; then
    echo "no rds host provided, exiting";
    exit;
else
        rds_host="-h"$3;
fi
if [ -z "$4" ]; then
    echo "no databae/schema provided, exiting";
    exit;
fi

if [ ! -z "$5" ]; then
    user="-u"$5;
fi

if [ ! -z "$6" ]; then
    password="-p"$6;
fi


echo "tenant_file: " $tenant_file;
echo "feature_file: " $feature_file;
echo "rds_host: " $rds_host;

if [ ! -f $tenant_file ]; then
        echo $tenant_file "does not exist, exiting";
        exit;
fi

if [ ! -f $feature_file ]; then
        echo $feature_file "does not exist, exiting";
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
        echo "Domain Name: " $domainname;
        echo "Parent Domain Name: " $parentdomainname;
        echo "School Name: " $schoolname;
        tenant_name=$domainname"."$parentdomainname;
        echo "Tenant Name: " $tenant_name;
        collabserver_url="https://"$domainname"-collab."$parentdomainname;
        echo "collabserver_url :" $collabserver_url;
        teacher_workspace_url=$domainname"."$parentdomainname"/classflow";
        echo "teacher_workspace_url :" $teacher_workspace_url;
        host_url="https://"$domainname"."$parentdomainname;
        echo "host_url :" $host_url;

        tenant_schema_name="af_"${domainname//./_};
        echo "tenant_schema_name :" $tenant_schema_name;
        #test if this is an insert or an update
        tenant_id=($(mysql -A $rds_host $user $password  $database  -Bse "select id from tenant_config where tenant_name = \"$tenant_name\" ;"))
        if [ ! -z $tenant_id ]; then
                echo "      (this will be an update)";
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set tenant_name = \"$tenant_name\" where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set datasource_id = \"$datasource_id\" where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set reporting_datasource_id = \"$datasource_id\" where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set active = FALSE where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set schema_name = \"$tenant_schema_name\" where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set last_updated_on = NOW() where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set last_updated_by = \"bulk insert update\" where id = \"$tenant_id\" ;"))
                update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set display_name = \"$schoolname\" where id = \"$tenant_id\" ;"))
        else
                echo "     (this will be an insert)";
                tenant_id=($(mysql -A $rds_host $user $password  $database  -Bse "select uuid() ;"));
                tenant_id=${tenant_id//-/};
                insert_new_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "insert into tenant_config (id, datasource_id,reporting_datasource_id,tenant_name,schema_name, created_on, created_by, last_updated_on, last_updated_by,display_name) values (\"$tenant_id\",\"$datasource_id\",\"$datasource_id\",\"$tenant_name\",\"$tenant_schema_name\",now(),\"bulk insert\",now(),\"bulk insert\",\"$schoolname\") ;"))
        fi
        echo "Using tenant_id" $tenant_id;
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set active = TRUE where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set is_default_tenant = FALSE where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set full_sisload = FALSE where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set concurrent_sessions = -1 where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set trial_period = -1 where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set default_tenant_community_name = \"$communityname\" where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set collabserver_url = \"$collabserver_url\" where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set teacher_workspace_url = \"$teacher_workspace_url\" where id = \"$tenant_id\" ;"))
        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_config set host_url = \"$host_url\" where id = \"$tenant_id\" ;"))

        let "n = 0";
        while read feature ref_feature_code_id; do
                let "n = $n + 1";
                echo " feature " $n ": " $feature " ref_code: " $ref_feature_code_id;
                feature_id=($(mysql -A $rds_host $user $password  $database  -Bse "select id from tenant_feature where tenant_config_id = \"$tenant_id\" and ref_feature_code_id = \"$ref_feature_code_id\" ;"))
                if [ ! -z $feature_id ]; then
                        echo "      (this will be feature update)";
                        update_tenant=($(mysql -A $rds_host $user $password  $database  -Bse "update tenant_feature set enabled = TRUE, last_updated_on = NOW(), last_updated_by = \"bulk feature insert\" where id = \"$feature_id\" ;"))
                else
                        echo "     (this will be feature insert)";
                        feature_id=($(mysql -A $rds_host $user $password  $database  -Bse "select uuid() ;"));
                        feature_id=${feature_id//-/};
                        insert_new_feature=($(mysql -A $rds_host $user $password  $database  -Bse "insert into tenant_feature (id, tenant_config_id,ref_feature_code_id,enabled, created_on, created_by, last_updated_on, last_updated_by) values (\"$feature_id\",\"$tenant_id\",\"$ref_feature_code_id\",TRUE,now(),\"bulk feature insert\",now(),\"bulk feature insert\") ;"))
                fi
        done < $feature_file;
        echo "Feature Count: " $n;
        #end of insert update conditon
done < $tenant_file;
IFS=$OLDIFS;
