###########################################
# Cookbook Name:: prom-storeservice
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
  node.force_default['newrelic']['application_monitoring']['app_name'] = 'store-service'
end

storeservice_version = node['applications']['backend']['storeservice_version']

unless node['database']['authdbserver'].nil? || node['database']['authdbserver'].empty?
  mysqlserver = node['database']['authdbserver']
else
  mysqlserver = node['database']['dbserver']
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

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end

yum_package 'store-service' do
  version storeservice_version
  action :install
  not_if { storeservice_version == "0.0.0-1" }
  notifies :restart, 'service[activtomcat]'
end

template '/opt/tomcat/conf/store-service.properties' do
  source 'store-service.properties.erb'
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

include_recipe 'prom-storeservice::logback'
