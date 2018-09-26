#
# Cookbook Name:: atlassian
# Recipe:: vpn
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"
#include_recipe "iptables::default"

#iptables_rule "port_ssh"
#iptables_rule "port_vpn"

execute "yum-update" do
  command "yum update"
  action :nothing
end

service "ipsec" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

service "iptables" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:stop, :disable]
end

%w{openswan}.each do |package|
  package package do
    :upgrade
  end
end

template "/etc/ipsec.conf" do
  source "ipsec.conf.erb"
  owner  "root"
  group  "root"
  mode   "0600"
  notifies :restart, "service[ipsec]"
end

template "/etc/ipsec.d/promethean.conf" do
  source "promethean.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[ipsec]"
end

template "/etc/ipsec.d/promethean.secrets" do
  source "promethean.secrets.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[ipsec]"
end

