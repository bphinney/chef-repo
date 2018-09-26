#
# Cookbook Name:: prom-provisioner
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-default::hostsfile'

# Dependency for deprecated provisioner application
include_recipe 'java::openjdk'

# configure tomcat user
include_recipe 'prom-activtomcat::usermanagement'

# Installs chef-api-gem
include_recipe 'prom-chef::chef-api-gem'

# Install required packages and gem dependencies
%w{ MySQL-client rubygem-mysql2 MySQL-devel MySQL-shared MySQL-shared-compat }.each do |pkg|
  yum_package pkg do
    action :upgrade
  end
end

# Install other gem dependencies
%w{ mysql2 logify mime-types }.each do |pkg|
  gem_package pkg do
    action :install
  end
end

# Remove old provisioner RPM
package "provisioner" do
  action :remove
end

# Deploy provisioning script
cookbook_file '/opt/provisioner/chef_tenant_provision' do
  mode  '0755'
  source 'chef_tenant_provision'
  action :create
end

# Set required directories
%w{ /opt/provisioner/logs /opt/provisioner/conf /opt/provisioner/scripts }.each do |dir|
  directory dir do
    owner 'tomcat'
    group 'tomcat'
    recursive true
    not_if "test -d #{dir}"
  end
end

template '/opt/provisioner/conf/provisioner.conf' do
  source 'provisioner.conf.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end

# Bulk fconfig loading script provided per CF-22593
cookbook_file '/opt/provisioner/scripts/bulk_provision.sh' do
  source 'bulk_provision.sh'
  owner  'tomcat'
  group  'tomcat'
  mode   '0755'
end

# Bulk fconfig loading script provided per CF-22593
cookbook_file '/opt/provisioner/scripts/bulk_users.sh' do
  source 'bulk_users.sh'
  owner  'tomcat'
  group  'tomcat'
  mode   '0755'
end


chef_server_url = node['chef_server_url']

# Basic knife.rb for chef api access
directory '/root/.chef' do
  owner 'root'
  group 'root'
  mode  '0755'
end

include_recipe "prom-default::chefclient"
#template '/root/.chef/knife.rb' do
#  source 'knife.rb.erb'
#  owner  'root'
#  group  'root'
#  mode   '0644'
#  variables(
#    chef_server_url: chef_server_url
#  )
#end

#Install prom-ops directory from templates
include_recipe "prom-chef::promops"
