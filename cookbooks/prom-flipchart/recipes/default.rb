#
# Cookbook Name:: prom-flipchart
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'promaws'
include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-default::selinux'
include_recipe 'prom-default::hostsfile'
include_recipe 'prom-activtomcat::activtomcat'
include_recipe 'prom-presearch'

unless node.chef_environment.include?('local')
  include_recipe 'glusterfs::glusterfs-af'
end

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.force_default['newrelic']['application_monitoring']['app_name'] = 'flipchart'
end

%w{qt qt-x11}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

execute 'ldconfig' do
  command 'ldconfig'
  action :nothing
end

flipchart_version = node['applications']['backend']['flipchart_version']

yum_package 'flipchart' do
  version flipchart_version
  action :install
  allow_downgrade true
  not_if { flipchart_version == '0.0.0-1' }
  notifies :restart, 'service[activtomcat]'
  notifies :run, 'execute[ldconfig]'
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

# Commenting out, this is all being done by the glusterfs-af recipe
#nfsserver = []
#if (Chef::Config[:solo] || node.chef_environment.include?('local'))
#  Chef::Log.warn("Excluding NFS-SERVER hostsfile entry in local/solo mode")
#else
#  $presearch_node['nfs_primaries'].each do |server|
#    nfsserver << server['ipaddress']
#  end
#  nfsserver=nfsserver.first
  #search(:node, "recipes:glusterfs\\:\\:nfs-server").each do |server|
  #  hostsfile_entry server['ipaddress'] do
  #    hostname server['hostname']
  #    action :create
  #    unique true
  #  end
#  end
#end

if node.chef_environment.include?('local')
  importenv = '/import'
else
  importenv = "/#{node.chef_environment}/import"
end

#Rabbitmq AV_Zone Selection
if node['provider'] == 'aws'
  unless node['aws'].nil? || node['aws'].empty? || node['aws']['av_zone'].nil? || node['aws']['av_zone'].empty?
    zone = node['aws']['av_zone']
    Chef::Log.info("Zone selected: #{zone}")
  end
end

rmqaddresses = ''
if Chef::Config[:solo] || "#{node['aws']}" == "" || node.chef_environment.include?("local")
  Chef::Log.warn('Single mode or AWS AV zone unavailable.')
  rmqaddresses = '127.0.0.1:5672'
else
  $presearch_node['rabbitmq_nodes'].each do |rabbitnode|
    if rabbitnode.inspect.include?("av_zone\"=>\"#{node['aws']['av_zone']}")
      rmqaddresses += "#{rmqaddresses}" == '' ? "" : ","
      rmqaddresses += "#{rabbitnode['ipaddress']}:5672"
    end
  end
end

template '/opt/tomcat/conf/flipchart-integration.properties' do
  source 'flipchart-integration.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[activtomcat]'
  variables(
    :rmqaddresses => rmqaddresses
  )
end

include_recipe 'prom-flipchart::logback'
