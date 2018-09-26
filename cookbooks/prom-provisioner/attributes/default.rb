# Chef Attributes for prom-provisioner
# Configuration File Defaults
default['provisioner']['daemonized'] = 'false'
default['provisioner']['log_level']  = 'info' #debug-info-warn-error-fatal-unknown
default['provisioner']['log_file']   = '/opt/provisioner/logs/provisioner.log'
default['provisioner']['log_header'] = '(chef->tenant_prov):'
