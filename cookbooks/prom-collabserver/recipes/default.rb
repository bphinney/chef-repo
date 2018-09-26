#
# Cookbook Name:: prom-collabserver
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-presearch'
include_recipe 'java::openjdk'
include_recipe 'prom-default'
include_recipe 'prom-default::repo'

# Newrelic attributes
if node.recipes.include?('newrelic')
  node.force_default['newrelic']['application_monitoring']['app_name'] = 'collabserver'
end

# If collab_type is not vertx include activfoundation recipe 
unless node['collab']['collab_type'] == 'vertx'
  include_recipe 'prom-activtomcat::activtomcat'
end

# Quickfix cleanup for old Vertx components in Vagrant Box centos65.
if node.chef_environment == 'local'
  execute 'clear_old_vertx_components' do
    command 'rm -rf /opt/vertx'
    action :run
    only_if {File.exist?('/opt/vertx/webapps/collabserver.zip')}
  end
end

# Lookup ip addresses for nodes for hazelcast clustering
solonode    = node
activnodes  = []
collabnodes = []
hazelnodes  = []
if Chef::Config['solo']
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.')
  activnodes = solonode['ipaddress']
else
  unless node.environment.include?('local') 
    unless node['collab']['collab_type'] == 'vertx'
      $presearch_node['activfoundation_nodes'].each do |member|
        unless member['ipaddress'].nil?
          activnodes << member['ipaddress']
        end
      end
    else
      $presearch_node['collabserver_nodes'].each do |member|
        unless member['ipaddress'].nil?
          collabnodes << member['ipaddress']
        end
      end
      $presearch_node['activfoundation_nodes'].each do |member|
        unless member['ipaddress'].nil?
          activnodes << member['ipaddress']
        end
      end   
    end
  else
    activnodes << '127.0.0.1'
    hazelnodes << '127.0.0.1'
  end
  collab_node_count = activnodes.count
  hazelnodes = activnodes + collabnodes
  activnodes = activnodes.collect { |worker| worker }.sort.uniq.join(',')
  hazelnodes = hazelnodes.collect { |worker| worker }.sort.uniq.join(',')
end



# Lookup the url for the default tenant in the environment
env       = node.chef_environment
tenants   = search(:foundation, "env:#{env}")
tenant_id = ''
tenants.each do |tenant|
  if tenant['tenant_config.is_default_tenant'] == "\u0001"
    tenant_id = tenant['tenant_config.collabserver_url']
  end
end

if node['platform_version'].to_i == '7'
  template '/usr/local/bin/collabserver' do
    source 'collabserver-init.erb'
    owner  'root'
    group  'root'
    mode   '0755'
  end
  cookbook_file '/usr/lib/systemd/system/collabserver.service' do
    source 'collabserver-init-cent7'
    owner  'root'
    group  'root'
    notifies :restart, 'service[collabserver]'
  end
else
  template '/etc/init.d/collabserver' do
    source 'collabserver-init.erb'
    owner  'root'
    group  'root'
    mode   '0755'
    notifies :restart, 'service[collabserver]'
  end
end

collabserver_version = node['applications']['collabserver']['collabserver_version']

# Setup service
package 'collabserver' do
  version collabserver_version
  action :install
  not_if { collabserver_version == '0.0.0-1' }
  notifies :restart, 'service[collabserver]'
end

include_recipe 'prom-collabserver::activvertx-remove'

include_recipe 'prom-activtomcat::usermanagement'

group 'tomcat' do
  gid '496'
  action :create
  not_if { node['etc']['group']['tomcat'] }
end

user 'tomcat' do
  uid '495'
  gid '496'
  home '/home/tomcat'
  shell '/bin/bash'
  action :create
  not_if { node['etc']['passwd']['tomcat'] }
end

%w{/opt/vertx /opt/vertx/logs /opt/vertx/conf /opt/vertx/cache /opt/vertx/bin /opt/vertx/fileupload}.each do |dir|
  directory dir do
    owner 'tomcat'
    group 'tomcat'
    recursive true
    not_if "test -d #{dir}"
  end
end

zkaddresses = ''
if Chef::Config[:solo] || "#{node['aws']}" == "" || node.chef_environment.include?('local')
  Chef::Log.warn('WARNING: Single mode or AWS AV zone unavailable.')
  zkaddresses = '127.0.0.1'
else
  $presearch_node['zookeeper_nodes'].each do |zookeepernode|
    zkaddresses += "#{zkaddresses}" == '' ? '' : ','
    zkaddresses += "#{zookeepernode['ipaddress']}:2181"
  end
end

#Rabbitmq AV_Zone Selection
if node["provider"] == "aws"
  unless node['aws'].nil? || node['aws'].empty? || node['aws']['av_zone'].nil? || node['aws']['av_zone'].empty?
    zone = node['aws']['av_zone']
    Chef::Log.info("Zone selected: #{zone}")
  end
end

rmqaddresses = ''
if Chef::Config[:solo] || "#{node['aws']}" == "" || node.chef_environment.include?("local")
  Chef::Log.warn("WARNING: Single mode or AWS AV zone unavailable.")
  rmqaddresses = "127.0.0.1:5672"
else
  $presearch_node['rabbitmq_nodes'].each do |rabbitnode|
    if rabbitnode.inspect.include?("av_zone\"=>\"#{node['aws']['av_zone']}")      
      rmqaddresses += "#{rmqaddresses}" == '' ? "" : ","
      rmqaddresses += "#{rabbitnode['ipaddress']}:5672"
    end
  end
end


template '/opt/vertx/conf/collabserver.properties' do
  source 'collabserver.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[collabserver]'
  variables(
           :activnodes  => activnodes,
           :rmqaddresses => rmqaddresses,
           :tenant_id   => tenant_id,
           :zkaddresses => zkaddresses,
           :collab_node_count => collab_node_count,
           :hazelnodes => hazelnodes
  )
end


template '/etc/cron.daily/collabserver-logs' do
  source 'collabserver-purge.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

if node['java']['jmx_console_enable'] == 'true' 
  template '/opt/tomcat/conf/jmxremote.access' do
    source 'jmxremote.access.erb'
    owner  'tomcat'
    group  'tomcat'
    mode   '0600'
    notifies :restart, 'service[collabserver]'
  end
  template '/opt/tomcat/conf/jmxremote.password' do
    source 'jmxremote.password.erb'
    owner  'tomcat'
    group  'tomcat'
    mode   '0600'
    notifies :restart, 'service[collabserver]'
  end
end

service 'collabserver' do
  supports :stop => true, :start => true, :restart => true, :status => true
  action [:enable, :start]
end

include_recipe "prom-collabserver::logback"
