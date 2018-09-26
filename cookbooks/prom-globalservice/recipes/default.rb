###########################################
# Cookbook Name:: prom-globalservice
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
  node.force_default['newrelic']['application_monitoring']['app_name'] = 'global-service'
end

globalservice_version = node['applications']['backend']['globalservice_version']

mysqlserver = node['database']['dbserver']

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

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end

yum_package 'global-service' do
  version globalservice_version
  action :install
  not_if { globalservice_version == "0.0.0-1" }
  notifies :restart, 'service[activtomcat]'
end

template '/opt/tomcat/conf/global-service.properties' do
  source 'global-service.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[activtomcat]'
  variables(
    :rmqaddresses => rmqaddresses,
    :emailserver => mailserver["smtpserver"],
    :emailuser => mailserver["smtpuser"],
    :emailpass => mailserver["smtppass"]
  )
end

cookbook_file "/opt/tomcat/security/iphone_dev.p12" do
  source "iphone_dev.p12"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

include_recipe 'prom-globalservice::logback'
