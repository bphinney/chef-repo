#
# Cookbook Name:: prom-chef
# Recipe:: postfix
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Configures postfix relay on chef-server for nagios forwarding
#

include_recipe "prom-default"

service "postfix" do
  supports :start => true, :restart => true, :stop => true, :status => true, :reload => true
  action :nothing
end

template "/etc/postfix/main.cf" do
  source "main.cf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :reload, "service[postfix]"
end

template "/etc/postfix/master.cf" do
  source "master.cf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :reload, "service[postfix]"
end

# IN-1218 - Remove chef-deploy script from chef-server
#           Where it is no longer used
file "/usr/local/bin/chef-deploy" do
  if node.name == 'chef-server'
    action :delete
  end
end
