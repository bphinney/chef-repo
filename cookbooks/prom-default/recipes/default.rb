#
# Cookbook Name:: prom-default
# Recipe:: default
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Include yumcache recipe which rebuilds the yum cache if the attribute is set.
include_recipe "prom-default::yumcache"
# Include yumepel recipe which adds epel repository to centos nodes.
include_recipe "prom-default::yumepel"
# include geminsecure recipe for china data center, no https for gem installations
include_recipe "prom-default::geminsecure"
# include chefclient recipe which controls daemon mode or cron entry for chefclient.
include_recipe "prom-default::chefclient"
# Don't assume that the promethean repo is present
unless node.recipes.include?("prom-yumrepo")
  include_recipe "prom-default::repo"
end

if (Chef::Config[:solo] or node.chef_environment.include?("local"))
  puts "Skipping NRPE load"
else
  include_recipe "prom-default::geminsecure"
  include_recipe "prom-nrpe"
  include_recipe "promaws::default"
end

# Adding crontab to run hostfile updates regularly
cron "hostfile-update" do
  command "/usr/bin/chef-client -o prom-default::hostsfile_update > /var/log/chef/hostfile_updates.log 2>&1"
  minute "15"
  action :create
  not_if { node.chef_environment.include?("local") }
end

service "iptables" do
  action [:stop, :disable]
  not_if { "#{node['iptables_enable']}" == "true" or node.recipes.include?('chefserver')  }
end

service "firewalld" do
  action [:disable, :stop]
  only_if { node['platform_version'].to_i == '7' }
end

package "ntp" do
  action :upgrade
end

%w{ntpd}.each do |service|
  service service do
    action [:enable, :start]
  end
end

template "/usr/bin/yum-update" do
  source "yum-update.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/usr/local/bin/chef-run" do
  source "chef-run.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/etc/sysconfig/network" do
  source "network.erb"
end

file "/etc/init.d/activplatform" do
  action :delete
end

unless node.environment.include?("local")
  execute 'swapoff' do
    command 'swapoff -a'
    not_if '[[ `free -m | grep -oP "^S[^1-9]+\K.."` == "0 " ]]'
  end
end

%w{12.7.2-1.el6}.each do |chefpkg|
  file "/opt/chef-#{chefpkg}.x86_64.rpm" do
    action :delete
    only_if { File.exist?("/opt/chef-#{chefpkg}.x86_64.rpm") }
  end
end
