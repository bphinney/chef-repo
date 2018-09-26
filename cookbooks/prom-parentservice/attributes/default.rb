# Authserver Default Attributes
default['applications']['parentservice_version'] = '0.0.0-1'
default['applications']['backend']['parentservice_version'] = '0.0.0-1'
# db endpoint
default['parent-service']['database'] = "parentservice#{node.chef_environment}"
default['parent-service']['username'] = 'parentsvcuser'
default['parent-service']['password'] = 'parentsvcpass'
default['parent-service']['terms_conds_ver'] = '1.0'
#Defaults for elasticsearch REST Service
default['elasticsearch']['rest_url'] = ''
default['elasticsearch']['rest_max_conn'] = '50'
default['elasticsearch']['rest_max_perhost'] = '50'
# Java Log Levels
default['foundationlog']['defaultloglevel'] = 'INFO'
default['foundationlog']['logger_parentloglevel'] = [ ]
# CMS Defaults
default['af']['cms_url'] = 'https://classflow.com'
default['af']['cms_guid'] = '706242d3-24d1-4149-afa9-03a830ac5c5d'
# Defaults for sockjs
default["af"]["sockjsprotocols"] = "iframe-eventsource,iframe-htmlfile,xhr-polling"
# Default for collabserver
default['collab']['collabhost'] = ''
# IN-1642 Basic Auth credentials
default['af']['intapiuser'] = "#{node.chef_environment}apiuser"
default['af']['intapipass'] = "#{node.chef_environment}apipass"
# OAuth Client credentials
default['af']['parclientid'] = "classflowclientid"
default['af']['parclientsecret'] = "secret"

