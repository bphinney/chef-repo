# Local server defaults
default['local']['localusername'] = "promethean"
default['local']['localuserpass'] = "Promethean1"
default['local']['localuserpasshash'] = "$1$3KXDj/NQ$dbhkX9bmE6ncUlkWxKygt0"
# Elasticsearch defaults
default['elasticsearch']['elasticsearch_version'] = "elasticsearch-1.5.2"
# IN-1496 - Defaults for Datawarehouse
default['dwh']['servername'] = "localhost"
# Analytics
default['dwh']['anaschemaname'] = "analytics#{node.chef_environment}"
default['dwh']['anausername'] = "anauser#{node.chef_environment}"
default['dwh']['anauserpass'] = "anauser#{node.chef_environment}pass"
# Datawarehouse
default['dwh']['dwhschemaname'] = "datawarehouse#{node.chef_environment}"
default['dwh']['supusername'] = "dwsuper#{node.chef_environment}"
default['dwh']['supuserpass'] = "dwsuper#{node.chef_environment}pass"
default['dwh']['rousername'] = "dwtenant#{node.chef_environment}"
default['dwh']['rouserpass'] = "dwtenant#{node.chef_environment}pass"
