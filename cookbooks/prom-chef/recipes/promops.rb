#
# Cookbook Name:: prom-chef
# Recipe:: promops
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Configures prom-ops library in specified root directories
#

include_recipe 'prom-default'

[
 '/opt/tools/foundation',
 '/opt/provisioner'
].each do |promopsroot|
  directory "#{promopsroot}/prom-ops" do
    owner 'root'
    group 'root'
    recursive true
    only_if "test -d #{promopsroot}"
  end
  [
    'apiconnect.rb',
    'awssecgroup.rb',
    'bootstrap.rb',
    'configtenant.rb',
    'daemonize.rb',
    'datacenter.rb',
    'emailsender.rb',
    'logging.rb',
    'sshconnect.rb',
    'tenantcheck.rb',
    'tenantprovision.rb'
  ].each do |opsscript|
    cookbook_file "#{promopsroot}/prom-ops/#{opsscript}" do
      source opsscript
      mode '0644'
      action :create
      only_if "test -d #{promopsroot}/prom-ops"
    end
  end
end
