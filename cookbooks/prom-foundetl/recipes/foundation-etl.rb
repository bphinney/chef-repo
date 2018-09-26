#
# Cookbook Name:: prom-foundetl
# Recipe:: foundation-etl
#
# Copyright 2016, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default::repo"
include_recipe "prom-activtomcat::activtomcat"

# Create local hosts file entry for our own IP address
include_recipe "prom-default::hostsfile"

include_recipe "promaws::default"

foundetl_version = node['applications']['backend']['foundetl_version']

yum_package "foundation-etl" do
  version foundetl_version
  action :install
  not_if { foundetl_version == '0.0.0-1' }
  notifies :restart, "service[activtomcat]"
end

template "/opt/tomcat/conf/etl.app.properties" do
  source "etl.app.properties.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  notifies :restart, "service[activtomcat]"
end

include_recipe "prom-foundetl::logback-etl-app"

