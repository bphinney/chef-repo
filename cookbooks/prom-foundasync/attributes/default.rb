# Default Versions
default['applications']['async_version'] = '0.0.0-1'
default['applications']['backend']['async_version'] = '0.0.0-1'
# Java Log Levels
default['foundationlog']['logger_asyncloglevel'] = [ ]
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
