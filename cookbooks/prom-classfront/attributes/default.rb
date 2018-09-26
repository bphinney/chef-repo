# Apache Attributes
default["apache"]["apacheservername"] = "localhost"
default["apache"]["maintenance"] = "false"   # true|false
default["apache"]["maintenance_bypass"] = "nobypass.classflow.com"
default['apache']['changetype'] = "reload" # Set this to either reload|restart 
default["apache"]["sslRedirect"] = "true"  # true|false
default["apache"]["aflbmethod"] = "http"   # http|ajp
default["apache"]["foundationconntype"] = "http"  # http|nio
default['apache']["security"] = "false"  # true|false
default['apache']['cf_elb'] = "localhost"
default['apache']['serverlimit'] = "80"
default['apache']['maxclients'] = "300"
default['apache']['static_install'] = "true"
default['apache']['allow_external'] = "false"
# Tomcat Defaults
default['tomcat']['sessions'] = "stateful"
# Default versions
default["applications"]["activwallsystem_version"] = "0.0.0-1"
default["applications"]["classflow_version"] = "0.0.0-1"
default["applications"]["uiadmin_version"] = "0.0.0-1"
default["applications"]["learner_version"] = "0.0.0-1"
default['applications']['uappapi_version'] = "0.0.0-1"
default["applications"]["webhelp_version"] = "0.0.0-1"
default["applications"]["mobileupdate_version"] = "0.0.0-1"

default['applications']['cmsplugin']['activwallsystem_version'] = '0.0.0-1'
default['applications']['frontend']['classflow_version'] = '0.0.0-1'
default['applications']['frontend']['uiadmin_version'] = '0.0.0-1'
default['applications']['frontend']['learner_version'] = '0.0.0-1'
default['applications']['frontend']['uappapi_version'] = '0.0.0-1'
default['applications']['frontend']['webhelp_version'] = '0.0.0-1'
default['applications']['frontend']['mobileupdate_version'] = '0.0.0-1'

# Default Countryblock
default["apache"]["php_errors"] = "Off"
default["apache"]["mpm"] = "prefork"
default['apache']['allow_external'] = "false"
default["countryblock"] = "MM,CU,IR,LY,KP,SD,SY"
default["cloudflare"]["cloudflare_ip_filter"] = "false"
default["cloudflare"]["cloudflare_ip_filter_method"] = "CFORIG"
# Default Attributes for php directives
default["disallow_indexing"] = "true"
default["php"]["directives"]["post_max_size"] = "8M"
default["php"]["directives"]["upload_max_filesize"] = "20M"
# Webhelp
default["webhelp"]["webhelpservername"] = "localhost"
default["webhelp"]["webhelp_install"] = "false"
# Parent-Service
default["parent_service"]["install"] = "false"
# Classflow
default["classflow"]["path_exclude_list"] = "server-status|classflow|teacher|student|learner|uappapi|maintenance|styles|activfoundation|foundation-management|embers|current|netcheck|static|management|webhelp|parent-service|global-service|store-service|authserver|error"
# dotcms
default['dotcms']['widgetservername'] = nil
