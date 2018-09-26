#########################################
# Cookbook Name:: prom-foundmanagement
# Recipe:: foundation-management
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#########################################
include_recipe 'prom-default::repo'
include_recipe 'prom-activtomcat::activtomcat'

# Create local hosts file entry for our own IP address
include_recipe 'prom-default::hostsfile'

unless  node['applications'].attribute?('backend') && node['applications']['backend'].attribute?('afmanagement_version')
  afmanagement_version = node['applications']['afmanagement_version']
else
  afmanagement_version = node['applications']['backend']['afmanagement_version']
end

yum_package 'foundation-management' do
  version afmanagement_version
  action :install
  not_if { afmanagement_version == '0.0.0-1' }
  notifies :restart, 'service[activtomcat]'
end

if node['database'].attribute?('dbserver')
  mysqlserver = node['database']['dbserver']
end

mail = node['emailservice']
begin
  mailserver = data_bag_item('email', mail)
rescue Net::HTTPServerException
  Chef::Log.info("No email information found in data bag item #{mail}")
end

template '/opt/tomcat/conf/foundation-management.properties' do
  source 'foundation-management.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[activtomcat]'
  variables(
    :mysqlserver => mysqlserver,
    :emailserver => mailserver['smtpserver'],
    :emailuser   => mailserver['smtpuser'],
    :emailpass   => mailserver['smtppass']
  )
end

include_recipe 'prom-foundmanagement::logback-management'
