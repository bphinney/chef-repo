#
# Cookbook Name:: prom-foundreport
# Recipe:: foundation-report
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-activtomcat::activtomcat'

foundreport_version = node['applications']['backend']['foundreport_version']
Chef::Log::info("Foundation-report version is #{foundreport_version}")
mysqlserver = node['database']['dbserver']

tenant_id = ''
env       = node.chef_environment
tenants = search(:foundation, "env:#{env}")
tenants.each do |tenant|
  if tenant['tenant_config.is_default_tenant'] == "\u0001"
    tenant_id = tenant['tenant_config.id']
  end
end

yum_package 'foundation-report' do
  version foundreport_version
  action :install
  not_if { foundreport_version == '0.0.0-1' }
  notifies :restart, 'service[activtomcat]'
end

template '/opt/tomcat/conf/report.properties' do
  source 'report.properties.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  variables(
    :mysqlserver => mysqlserver,
    :tenantid    => tenant_id
  )
end

include_recipe 'prom-foundreport::logback-report'
