# Default versions
default["applications"]["foundetl_version"] = "0.0.0-1"
# DB defaults
default["database"]["dbserver"] = "prometheandb.cum0ld45s8ef.us-east-1.rds.amazonaws.com:3306"
default["database"]["dbservername"] = "prometheandb.cum0ld45s8ef.us-east-1.rds.amazonaws.com"
default["founconfigdb"] = "fconfigdev"
default["founconfiguser"] = "fconfigdevuser"
default["founconfigpass"] = "fconfigdevpass"
# Activfoundation Attributes
default["af"]["activfoundb"] = "activfoundationdev"
default["af"]["activfoundbuser"] = "activplatuser"
default["af"]["activfoundbpass"] = "activplatpass"
default['af']['etl_cron'] = "0 0 0/12 * * ?"
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
