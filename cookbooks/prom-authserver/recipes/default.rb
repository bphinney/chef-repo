###########################################
# Cookbook Name:: prom-authserver
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
###########################################
include_recipe 'prom-presearch'
include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-activtomcat::activtomcat'
include_recipe 'prom-default::hostsfile'

# Newrelic attributes
if node.recipes.include?('newrelic')
  node.force_default['newrelic']['application_monitoring']['app_name'] = 'authserver'
end

# Non-local gluster for file services
unless node.chef_environment.include?("local")
  include_recipe "glusterfs::glusterfs-af"
end

# Application Versions
authserver_version = node['applications']['backend']['authserver_version']
# Mysql
unless node['database']['authdbserver'].nil? || node['database']['authdbserver'].empty?
  mysqlserver   = node['database']['authdbserver']
else
  mysqlserver	= node['database']['dbserver']
end
database        = node['authserver']['database']
authservuser    = node['authserver']['username']
authservpass    = node['authserver']['password']
# Authserver Properties
contextmode     = node['database']['contextmode']
frame_ancestors = node['authserver']['frame_ancestors']
issuer_url      = node['apache']['apacheservername']

yum_package 'authserver' do
  version authserver_version
  action :install
  not_if { authserver_version == '0.0.0-1' }
  notifies :restart, 'service[activtomcat]'
end

directory node['authserver']['fileservice_parent_dir'] do
  action :create
  owner  'tomcat'
  group  'tomcat'
  only_if "test -d /opt/tomcat/content"
end

directory "#{node['authserver']['fileservice_parent_dir']}/#{node['authserver']['custom_avatar_dir']}" do
  action :create
  owner  'tomcat'
  group  'tomcat'
  only_if "test -d #{node['authserver']['fileservice_parent_dir']}"
end

template '/opt/tomcat/conf/authserver.properties' do
  source 'authserver.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[activtomcat]'
  variables(
    :mysqlserver     => mysqlserver,
    :database        => database,
    :contextmode     => contextmode,
    :authservuser    => authservuser,
    :authservpass    => authservpass,
    :frame_ancestors => frame_ancestors,
    :issuer_url      => issuer_url,
  )
end

include_recipe 'prom-authserver::logback'
