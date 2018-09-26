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
default['apache']['deflate'] = "true"
default['apache']['proxy_retry'] = "120"
default['apache']['proxy_error'] = "501,502,503"
default['apache']['proxy_timeout'] = "30"
default['prworld']['deflate'] = "false"
# Default Countryblock
default["apache"]["php_errors"] = "Off"
default["apache"]["mpm"] = "prefork"
default['apache']['allow_external'] = "false"
default["countryblock"] = "MM,CU,IR,LY,KP,SD,SY"
default['apache']['internal_block'] = "52.27.23.34, 52.27.14.135, 52.88.82.146, 54.77.160.233, 52.28.92.140, 54.208.241.255, 52.50.50.51, 52.37.84.16, 52.37.27.63, 52.37.45.13, 54.164.71.168, 52.0.198.150, 52.87.91.56, 52.201.103.209, 52.201.103.187"
# Default Attributes for php directives
default["disallow_indexing"] = "true"
default["php"]["directives"]["post_max_size"] = "8M"
default["php"]["directives"]["upload_max_filesize"] = "20M"

