# Authserver Default Attributes
# Application Version
default["applications"]["authserver_version"] = "0.0.0-1"
# Log Levels
default['authserverog']['prom_log_level']  = 'INFO'
default['authserverlog']['authdefaultloglevel']       = 'INFO'
default['authserverlog']['logger_authserverloglevel'] = [ ]
# Authserver database properties
default['database']['dbserver']      = 'localhost'
default['authserver']['database']    = "authserv#{node.chef_environment}"
default['authserver']['username' ]   = 'authservuser'
default['authserver']['password']    = 'authservpass'
default['authserver']['frame_ancestors'] = "https://*.prometheanjira.com/ http://localhost:8888/ https://*.classflow.com/ https://classflow.com https://*.classflow.co.uk/ https://*.classflow.it/ https://*.classflow.de/ https://*.classflow.se/ https://*.classflow.nl/ https://*.classflow.lv/ https://*.classflow.ae/ https://*.classflow.com.au/ https://*.clasflow.cn/"
# Catalina Properties
# Override default *.jar setting with backslash per Mallik.
normal['tomcat']['jarstoskip'] = '\\'
default['authserver']['fileservice_parent_dir'] = "/opt/tomcat/content/file_services"
default['authserver']['custom_avatar_dir'] = "env_#{node.chef_environment}"
default['authserver']['avatar_max_size'] = "1000000"
