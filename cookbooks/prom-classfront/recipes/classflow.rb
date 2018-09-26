#
# Cookbook Name:: prom-classfront
# Recipe:: classflow
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-default::selinux'
include_recipe 'prom-default::hostsfile'
include_recipe 'prom-presearch::default'
include_recipe 'prom-classfront::netcheck'

# Newrelic attributes
if node.recipes.include?('newrelic')
  node.default['newrelic']['application_monitoring']['app_name'] = 'classflow'
end

# Newrelic Plugin
if node['newrelic']['newrelic-plugin-install'] == 'true'
  include_recipe 'prom-newrelic::newrelic-plugin'
end

# Perform default http actions
include_recipe 'prom-http::default'

# Install maintenance page components
include_recipe 'prom-classfront::maintenance'

service 'httpd' do
  if node['platform_version'].to_i == '7'
    stop_command '/bin/systemctl stop httpd'
    start_command '/bin/systemctl start httpd'
    reload_command '/usr/sbin/apachectl graceful'
    restart_command '/bin/systemctl restart httpd'
  else
    stop_command  '/etc/init.d/httpd stop'
    start_command '/etc/init.d/httpd start'
    reload_command '/etc/init.d/httpd graceful'
    restart_command '/etc/init.d/httpd restart'
  end
  supports stop: true, start: true, restart: true, status: true, reload: true, graceful: true
  action :nothing
end

# Action to run to check for configuration errors
# Also does a service call to restart `httpd`
execute 'configcheck' do
  command 'apachectl configtest'
  action :nothing
  notifies :"#{node['apache']['changetype']}", 'service[httpd]'
end

include_recipe 'prom-classfront::classflow-auth'

directory '/opt/storage' do
  recursive true
end

directory '/opt/www/classflow' do
  recursive true
  owner 'apache'
  group 'apache'
  action :create
end

classflow_version = node['applications']['frontend']['classflow_version']

yum_package 'classflow' do
  version classflow_version
  action :install
  allow_downgrade true
  not_if { classflow_version == '0.0.0-1' }
end

include_recipe 'prom-classfront::install-learner'
include_recipe 'prom-classfront::install-mobileupdate'
include_recipe 'prom-classfront::install-uiadmin'
include_recipe 'prom-classfront::install-uappapi'

###<-Begin Multi-Tenant Configuration
include_recipe 'prom-classfront::classflow-conf'

template '/etc/httpd/conf.d/vhost-global.load' do
  source 'vhost-global.load.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(
    :countryblock => node['countryblock'].split(',')
  )
  notifies :run, 'execute[configcheck]'
end

template '/etc/httpd/conf.d/cfredirect.load' do
  source 'cfredirect.load.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(
    :countryblock => node['countryblock'].split(',')
  )
  notifies :run, 'execute[configcheck]'
end

template '/etc/httpd/conf.d/cors.load' do
  source 'cors.load.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :delete
  notifies :run, 'execute[configcheck]'
  only_if { File.exists?('/etc/httpd/conf.d/cors.load') }
end

###############################################################################
##                      Backend Split if Necessary                           ##  
activfoundworkers = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef solo does not support search.')
else
  unless node.chef_environment.include?('local')
    # Search for foundation only nodes
    $presearch_node['aftraffic_nodes'].each do |worker|
      activfoundworkers << worker
    end
    if activfoundworkers.empty?
      $presearch_node['activfoundation_nodes'].each do |worker|
        activfoundworkers << worker
      end
    end
  else
    # In this section, we assume the environment is local so splitting is unnecessary
    search(:node, "role:backend AND name:#{node['hostname']}").each do |worker|
      activfoundworkers << worker
    end
  end
end
###############################################################################
activfoundnodes = []
activfoundworkers.each do |worker|
  activfoundnodes << worker['ipaddress']
end
activfoundnodes=activfoundnodes.uniq.sort.join(',')

activfoundworkers.uniq! { |a| a.ipaddress }
activfoundworkers.sort! { |a,b| a.ipaddress <=> b.ipaddress }
# Create activfoundation http proxy settings file
if node['apache']['aflbmethod'] == 'http'
  # Create activfoundation http proxy
  template '/etc/httpd/conf.d/activfoundation.proxy' do
    source 'activfoundation.proxy.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    variables(:activfoundworkers => activfoundworkers)
    not_if {activfoundworkers.nil? || activfoundworkers.empty?}
  end
  # Remove activfoundation ajp workers file
  template '/etc/httpd/conf.d/activfoundation.workers' do
    source 'activfoundation.workers.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    variables(:activfoundworkers => activfoundworkers,
              :activnodes        => activfoundnodes
             )
    action :delete
    only_if { File.exists?('/etc/httpd/conf.d/activfoundation.workers') }
  end
  # Remove activfoundation ajp load file
  template '/etc/httpd/conf.d/activfoundation.load' do
    source 'activfoundation.load.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    action :delete
    only_if { File.exists?('/etc/httpd/conf.d/activfoundation.load') }
  end
  # Remove activfoundation afjkload
  template '/etc/httpd/conf.d/activfoundation.jkload' do
    source 'activfoundation.jkload.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    action :delete
    only_if { File.exists?('/etc/httpd/conf.d/activfoundation.jkload') }
  end
end

if node['apache']['aflbmethod'] == 'ajp'
  # Install mod_jk
  remote_file '/etc/httpd/modules/mod_jk.so' do
    source 'https://yumrepo.prometheanjira.com/core/mod_jk.so'
    mode   '0755'
    action :create
    not_if { File.exists?('/etc/httpd/modules/mod_jk.so') }
    notifies :run, 'execute[configcheck]'
  end

  # Setup configuration for mod_jk workers file
  template '/etc/httpd/conf.d/activfoundation.workers' do
    source 'activfoundation.workers.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    variables(:activfoundworkers => activfoundworkers,
              :activnodes        => activfoundnodes
             )
    not_if {activfoundworkers.nil? || activfoundworkers.empty?}
  end

  # Config file for mod_jk load
  template '/etc/httpd/conf.d/activfoundation.load' do
    source 'activfoundation.load.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    not_if {activfoundworkers.nil? || activfoundworkers.empty?}
  end
  # Config file for afjkload
  template '/etc/httpd/conf.d/activfoundation.jkload' do
    source 'activfoundation.jkload.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    not_if {activfoundworkers.nil? || activfoundworkers.empty?}
  end
  # Remove standard activfoundation.proxy
  template '/etc/httpd/conf.d/activfoundation.proxy' do
    source 'activfoundation.proxy.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    notifies :run, 'execute[configcheck]'
    variables(:activfoundworkers => activfoundworkers)
    action :delete
    only_if { File.exists?('/etc/httpd/conf.d/activfoundation.proxy') }
  end
end

# Section to install afmanager frontend
include_recipe 'prom-classfront::afmanagerfront'

# Install authserver proxy endpoint if Authserver is part of the environment
if $presearch_node['authserver_nodes'].any?
  include_recipe 'prom-classfront::authserverfront'
end

# Install parent-service proxy endpoint if parent-service is part of the environment
if $presearch_node['parentservice_nodes'].any?
  include_recipe 'prom-classfront::parentservicefront'
end

# Install store-service proxy endpoint if store-service is part of the environment
if $presearch_node['storeservice_nodes'].any?
  include_recipe 'prom-classfront::storeservicefront'
end

# Install webhelp if attribute exists
if node.attribute?('webhelp') and node['webhelp']['webhelp_install'] == true
  include_recipe 'prom-classfront::webhelp'
end

# Install static content
include_recipe 'prom-classfront::static'

# Install dotcms recipe, it both installs and removes depending on attribute
include_recipe 'dotcms::dotcmsfront'

if node['provider'] == 'aws'
  include_recipe 'prom-classfront::classflow-elb'
end

if node.attribute?('cdn') and node['cdn'].attribute?('host')
  include_recipe 'prom-classfront::cloudfront'
elsif !node.attribute?('cdn') or !node['cdn'].attribute?('host')
  # remove the `mod_cdn` package
  package 'mod_cdn' do 
    action :remove
  end
  # Remove `cdn.*` files from `/etc/httpd/conf.d/` if they exist
  Dir.glob('/etc/httpd/conf.d/cdn.*').each do |conffile|
    file conffile do 
      action :delete
      only_if { File.exist?("#{conffile}") }
    end
  end
end


unless node.chef_environment.include?('local') || Dir.exists?('/opt/var/log')
  %w{haproxy auditd beaver httpd rsyslog}.each do |svc|
    service svc do
      action :stop
    end
  end
  package 'rsync' do
    action :install
  end
  execute 'relocate-logs' do
    command 'mkdir -p /opt/var/log && rsync -avHP /var/log/ /opt/var/log/ && rm -rf /var/log && ln -s /opt/var/log /var/log'
  end
  %w{haproxy auditd beaver httpd rsyslog}.each do |svc|
    service svc do
      action :start
      only_if "ls /etc/init.d | grep #{svc}"
    end
  end
  service 'chef-client' do
    action :restart
    only_if 'service chef-client status | grep -q running'
  end
  service 'newrelic-sysmond' do
    action :restart
    only_if 'service newrelic-sysmond status | grep -q running'
  end
end

