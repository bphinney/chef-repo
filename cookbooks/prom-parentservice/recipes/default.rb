###########################################
# Cookbook Name:: prom-parentservice
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
  node.force_default['newrelic']['application_monitoring']['app_name'] = 'parent-service'
end

unless node['applications'].attribute?('backend') && node['applications']['backend'].attribute?('parentservice_version')
  parent_service = node['applications']['parentservice_version']
else
  parent_service = node['applications']['backend']['parentservice_version']
end

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

yum_package 'parent-service' do
  version parent_service
  action :install
  notifies :restart, 'service[activtomcat]'
  not_if { parent_service == '0.0.0-1' }
end

template '/opt/tomcat/conf/parent-service.properties' do
  source 'parent-service.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  notifies :restart, 'service[activtomcat]'
  action :create
  variables(
    :rmqaddresses => rmqaddresses
  )
end

include_recipe 'prom-parentservice::logback'
