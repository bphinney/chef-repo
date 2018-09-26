#
# Cookbook Name:: prom-default
# Recipe:: chefclient
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

#include_recipe "omnibus_updater"
include_recipe "prom-default::chefclient-update"
include_recipe "prom-default::chefclient-clean"

directory "/var/log/chef" do
  recursive true
  :create
end

if node['platform_version'].to_i == '7' 
  cookbook_file '/usr/lib/systemd/system/chef-client.service' do
    source 'chef-client-init-cent7'
    owner 'root'
    group 'root'
    mode '0755'
  end 
  cookbook_file '/etc/sysconfig/chef-config' do
    source 'chef-client-init-cent7-options'
    owner 'root'
    group 'root'
    mode '0644'
  end 
else
  template "/etc/init.d/chef-client" do
    source "chef-client-init.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end 
end

template "/etc/logrotate.d/chef_client" do
  source "chef-client.logrotate.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

# IN-1193 - First-run deploy flag used for bootstrapping a node
if ENV['FIRST_DEPLOY'] == '1'
  include_recipe 'fqdn'
else
  template "/etc/chef/client.rb" do
    source "client.rb.erb"
    owner  "root"
    group  "root"
    mode   "0644"
  end
end

service "chef-client" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable, :start]
  only_if { node['chefclient_daemon'] == "true" }
end

#if node['chefclient_daemon'] == "true"
#  node.default['omnibus_updater']['restart_chef_service'] = "true"
#elsif node['chefclient_daemon'].nil? || node['chefclient_daemon'].empty? || node['chefclient_daemon'] == "false"
#  node.default['omnibus_updater']['restart_chef_service'] = "false"
#end

cron 'chef-restart' do
  if node['platform_version'].to_i == '7'
    command '/bin/systemctl restart chef-client > /var/log/chef/chef-restart.log 2>&1'
  else
    command "/sbin/service chef-client restart > /var/log/chef/chef-restart.log 2>&1"
  end
  minute "15"
  hour   "1"
  if node['chefclient_daemon'] == "true"
    action :create
  elsif node['chefclient_daemon'].nil? || node['chefclient_daemon'].empty? || node['chefclient_daemon'] == "false"
    action :delete
  end
end
