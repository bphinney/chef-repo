#
# Cookbook Name:: prom-foundload
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
include_recipe 'prom-presearch'
include_recipe 'prom-foundload::primary'

unless node['applications'].attribute?('backend') && node['applications']['backend'].attribute?('fload_version')
  fload_version = node['applications']['fload_version']
else
  fload_version = node['applications']['backend']['fload_version']
end

unless node['foundation-load'].nil? || node['foundation-load'].empty?
if node['foundation-load'] == 'primary'
  yum_package 'foundation-load' do
    version fload_version
    action :install
    allow_downgrade true
    not_if { fload_version == '0.0.0-1' }
    notifies :restart, 'service[activtomcat]'
  end

  directory '/opt/tomcat/import' do
    recursive true
    owner 'tomcat'
    group 'tomcat'
  end

  directory '/opt/tomcat/sisimport' do
    recursive true
    owner 'tomcat'
    group 'tomcat'
  end

  #Rabbitmq AV_Zone Selection
  if node['provider'] == 'aws'
    unless node['aws'].nil? || node['aws'].empty? || node['aws']['av_zone'].nil? || node['aws']['av_zone'].empty?
      zone = node['aws']['av_zone']
      Chef::Log.info("Zone selected: #{zone}")
    end
  end

  rmqaddresses = ''
  if Chef::Config[:solo] || "#{node['aws']}" == "" || node.chef_environment.include?('local')
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

  mysqlserver = node['database']['dbserver']

  ################################
  ## Default Tenant             ##
  ################################

  env       = node.chef_environment
  tenants   = search(:foundation, "env:#{env}")
  tenant_id = ''
  tenants.each do |tenant|
    if tenant['tenant_config.is_default_tenant'] == "\u0001"
      tenant_id = tenant['tenant_config.id']
    end
  end

  begin
    sftpinfo = data_bag_item('sftp', "foundation#{env}")
  rescue Net::HTTPServerException
    Chef::Log.info("No info found in data bag item foundation#{env}")
    sftpinfo = { 
      'foundationservername' => 'localhost',
      'foundationport'       => '22',
      'foundationadmin'      => 'xferadmin',
      'foundationpass'       => 'f1l3m0v3'
    }
  end

  template '/opt/tomcat/conf/foundation-load.properties' do
    source 'foundation-load.properties.erb'
    owner  'tomcat'
    group  'tomcat'
    mode   '0644'
    notifies :restart, 'service[activtomcat]'
    variables(
      :tenant_id    => tenant_id,
      :mysqlserver  => mysqlserver,
      :rmqaddresses => rmqaddresses,
      :sftp_host    => sftpinfo['foundationservername'],
      :sftp_port    => sftpinfo['foundationport'],
      :sftp_user    => sftpinfo['foundationadmin'],
      :sftp_pass    => sftpinfo['foundationpass']
    )
    end
  end
end

include_recipe 'prom-foundload::logback'
