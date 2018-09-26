#
# Cookbook Name:: prom-foundasync
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-default::hostsfile'
include_recipe 'prom-activtomcat::activtomcat'
include_recipe 'prom-activtomcat::foundation'
include_recipe 'promaws::default'
include_recipe 'prom-presearch'

unless node.chef_environment.include?('local')
  include_recipe 'glusterfs::glusterfs-af'
end

unless node['applications'].attribute?('backend') && node['applications']['backend'].attribute?('async_version')
  async_version = node['applications']['async_version']
else
  async_version = node['applications']['backend']['async_version']
end

yum_package 'foundation-async' do
  version async_version
  action :install
  allow_downgrade true
  not_if { async_version == '0.0.0-1' }
  notifies :restart, 'service[activtomcat]'
end

directory '/opt/tomcat/content' do
  recursive true
  owner 'tomcat'
  group 'tomcat'
  not_if 'test -d /opt/tomcat/content'
end

if node['af']['content_fallback'] == "true"
  directory "/opt/tomcat/contentback" do
    owner  "tomcat"
    group  "tomcat"
  end
end

#nfsserver = []
#if (Chef::Config[:solo] || node.chef_environment.include?('local'))
#  Chef::Log.warn('Excluding NFS-SERVER hostsfile entry in local/solo mode')
#else
#  search(:node, 'nfs-server:primary').each do |server|
#    nfsserver << server['ipaddress']
#  end
#  nfsserver=nfsserver.first
#  search(:node, "recipes:glusterfs\\:\\:nfs-server").each do |server|
#    hostsfile_entry server['ipaddress'] do
#      hostname server['hostname']
#      action :create
#      unique true
#    end
#  end
#end

if node.recipes.include?('glusterfs::glusterfs-af')
  contentenv = "/#{node.chef_environment}/content"
  importenv  = "/#{node.chef_environment}/import"
else
  contentenv = ''
  importenv  = '/import'
end

execute 'change-permissions' do
  command 'chown tomcat.tomcat /opt/tomcat/content; chown tomcat.tomcat /opt/tomcat/content/import'
  action :nothing
end

directory '/opt/tomcat/content' do
  recursive true
  owner 'tomcat'
  group 'tomcat'
  notifies :run, 'execute[change-permissions]'
end

directory '/opt/tomcat/content/import' do
  recursive true
  owner 'tomcat'
  group 'tomcat'
  notifies :run, 'execute[change-permissions]'
end

# Rabbitmq AV_Zone Selection
if node['provider'] == 'aws'
  unless node['aws'].nil? || node['aws'].empty? || node['aws']['av_zone'].nil? || node['aws']['av_zone'].empty?
    zone = node['aws']['av_zone']
    Chef::Log.info("Zone selected: #{zone}")
  end
end

rmqaddresses = ''
if Chef::Config[:solo] || "#{node['aws']}" == '' || node.chef_environment.include?('local')
  Chef::Log.warn('WARNING: Single mode or AWS AV zone unavailable.')
  rmqaddresses = '127.0.0.1:5672'
else
  $presearch_node['rabbitmq_nodes'].each do |rabbitnode|
    if rabbitnode.inspect.include?("av_zone\"=>\"#{node['aws']['av_zone']}")
      rmqaddresses += "#{rmqaddresses}" == '' ? "" : ","
      rmqaddresses += "#{rabbitnode['ipaddress']}:5672"
    end
  end
end

mysqlproxy = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef solo does not support search.')
else
  search(:node, 'role:mysqlproxy' ).each do |mysql|
    mysqlproxy << mysql['ipaddress']
  end
end
mysqlproxy = mysqlproxy.join

if mysqlproxy.nil? || mysqlproxy.empty?
  mysqlserver = node['database']['dbserver']
else
  mysqlserver = "#{mysqlproxy}:4040"
end

# Elasticsearch nodes
elasticnodes = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.')
  elasticnodes = solonode['ipaddress']
else
  unless node.chef_environment.include?('local')
    $presearch_node['elasticsearch_nodes'].each do |elastic|
      elasticnodes << elastic['ipaddress']
    end
    elasticnodes = elasticnodes.collect { |worker| worker }.sort.uniq.join(',')
  else
    elasticnodes << '127.0.0.1'
    elasticnodes = elasticnodes.collect { |worker| worker }.sort.uniq.join(',')
  end
end

unless node['elasticsearch_service'].nil? || node['elasticsearch_service'].empty?
  elasticnodes = node['elasticsearch_service']
end

template '/opt/tomcat/conf/foundation-async.properties' do
  source 'foundation-async.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[activtomcat]'
  variables(
    :mysqlserver  => mysqlserver,
    :rmqaddresses => rmqaddresses,
    :elasticnodes => elasticnodes
  )
end

include_recipe 'prom-foundasync::logback'
include_recipe 'prom-activfoundation::aspose-lic'

