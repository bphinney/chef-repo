# Default Versions
default['applications']['fload_version'] = '0.0.0-1'
default['applications']['backend']['fload_version'] = '0.0.0-1'
# Java Log Levels
default['foundationlog']['logger_loadloglevel'] = [ ]
# Foundation Load defaults
default['floadqueuename'] = 'ha.elasticsearch'
default['floaderrqueuename'] = 'ha.elasticsearch.error'
default['floadroutingkey'] = 'elasticsearch.*'
default['floadconsumers'] = '2'
default['floaderrroutingkey'] = 'elasticsearch.error.*'
