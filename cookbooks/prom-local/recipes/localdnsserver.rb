#
# Cookbook Name:: prom-local
# Recipe:: localdnsserver
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

package "bind" do
  action :upgrade
end

service "iptables" do
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true, :enable => true
  action [:stop, :disable]
end

service "named" do
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true, :enable => true
  action :nothing
end

template "/etc/named.conf" do
  source "named.conf.erb"
  notifies :reload, "service[named]"
end

template "/etc/named/db.classflow.lan" do
  source "db.classflow.lan.erb"
  notifies :reload, "service[named]"
end

append_if_no_line "ifcfg-eth0" do
  path "/etc/sysconfig/network-scripts/ifcfg-eth0"
  line "DNS1=#{node['ipaddress']}"
  only_if { File.exists?("/etc/sysconfig/network-scripts/ifcfg-eth0") }
end

append_if_no_line "ifcfg-em1" do
  path "/etc/sysconfig/network-scripts/ifcfg-em1"
  line "DNS1=#{node['ipaddress']}"
  only_if { File.exists?("/etc/sysconfig/network-scripts/ifcfg-em1") }
end

cookbook_file "/usr/bin/data-backup" do
  source "data-backup"
  owner  "root"
  group  "root"
  mode   "0755"
end

service "named" do
  action [:start, :enable]
end

# Create user account for local user
user node['local']['localusername'] do
  supports :manage_home => true
  comment "This user created by chef for local management"
  home "/home/#{node['local']['localusername']}"
  password node['local']['localuserpasshash']
  shell "/bin/bash"
end

#Add sudoers file to allow chef-client run
template "/etc/sudoers.d/localchef" do
  source "localchef.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

