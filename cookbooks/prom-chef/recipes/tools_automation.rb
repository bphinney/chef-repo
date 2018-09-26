#
# Cookbook Name:: promethean
# Recipe:: tools_automation 
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# chef-server recipes to support tools repo features and Souschef

# Include necessary recipes
include_recipe "java::openjdk"
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "yum::default"

service "souschef" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/local/bin/souschef stop"
    start_command "/usr/local/bin/souschef start"
    reload_command "/usr/local/bin/souschef reload"
    restart_command "/usr/local/bin/souschef restart"
  end
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

# Install necessary Chef Gems
%w{ cloudflare colorize json logger mysql2 sinatra terminal-table timeout tty-prompt vine }.each do |gem|
  gem_package gem do
    action :install
  end
end
 
# Note: temporary inclusion of chef-api gem bypass for chef-server (IN-1031)
gem_package 'chef-api' do
  action :install
  not_if { node["chef_api"].attribute?("chef_api_patch") && node["chef_api"]["chef_api_patch"] == "true"}
end

# Install necessary Yum Packages
%w{rubygem-mysql2 MySQL-devel MySQL-shared MySQL-shared-compat}.each do |pkg|
  yum_package pkg do
    action :upgrade
  end
end

link "/etc/rc.d/init.d/souschef" do
  to "/opt/souschef/souschef"
  only_if "test -d /opt/souschef"
end

# Creating link for souschef
link "/usr/local/bin/souschef" do
  to "/opt/souschef/souschef"
  only_if "test -d /opt/souschef"
end

#Pull Tools Repos
tools_version = node['applications']['tools']['tools_version']
souschef_version = node['applications']['tools']['souschef_version']

package "tools" do
  version tools_version
  action :install
  not_if { tools_version == '0.0.0-1' }
end

package "souschef" do
  version souschef_version
  action :install
  notifies :restart, "service[souschef]"
  not_if { souschef_version == '0.0.0-1' }
end

#Include recipe to install chef-api-gem via RPM
include_recipe "prom-chef::chef-api-gem"

# Databag look up of appnames and write to node attribute
app_names = data_bag_item('activfoundation', 'applications')
appnames = ""
rpmlist = ""
app_names["names"].each do |name,version|
  appnames = appnames + "#{name}|#{version} "
  rpmlist += "#{name} #{version}\n"
end
#Chef::Log.info("appnames string will be #{appnames}")
file "/opt/souschef/rpmlist" do
  content "#{rpmlist}"
  mode "0644"
  owner "root"
  group "root"
end

# Open data bag item for users for the tools package
userdata = search(:tools)

template "/opt/souschef/users" do
  source "users.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables( :users => userdata )
  notifies :restart, "service[souschef]"
end

template "/opt/souschef/users.shadow" do
  source "users.shadow.erb"
  owner  "root"
  group  "root"
  mode   "0640"
  variables( :users => userdata )
  notifies :restart, "service[souschef]"
end

#Install prom-ops directory from templates
include_recipe "prom-chef::promops"

