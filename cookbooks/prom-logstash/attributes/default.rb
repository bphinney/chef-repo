# Defaults for logstash server
default['logstash']['version'] = "2.2.2-1"
default['logstash']['plugins'] = "logstash-input-redis logstash-output-elasticsearch logstash-filter-grok logstash-filter-mutate logstash-patterns-core"
default['logstash']['logstash_elbname'] = "LogstashELB"
# Defaults for kibana
default['kibana']['es_port'] = "9200"
# Defaults for Apache Attributes
default["apache"]["apacheservername"] = "localhost"
default["apache"]["maintenance"] = "false"
default["apache"]["maintenance_bypass"] = "nobypass.classflow.com"
default['apache']['changetype'] = "reload"
default["apache"]["sslRedirect"] = "true"
default["apache"]["aflbmethod"] = "http"          # http|ajp
default["apache"]["foundationconntype"] = "http"  # http|nio
default['apache']["security"] = "false"
default['apache']['cf_elb'] = "localhost"
default['apache']['serverlimit'] = "80"
default['apache']['maxclients'] = "300"
default['apache']['static_install'] = "true"
default['apache']['allow_external'] = "false"
default['apache']['default_site_enabled'] = "false"
default['apache']['listen_ports'] = ['80']
default['apache']['binary'] = "false"

