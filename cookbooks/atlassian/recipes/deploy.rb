#
# Cookbook Name:: atlassian
# Recipe:: deploy
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#


include_recipe "prom-default"
include_recipe "prom-presearch"
include_recipe "prom-default::hostsfile_update"

service "postfix" do
  supports :start => true, :restart => true, :stop => true, :status => true, :reload => true
  action :nothing
end

template "/usr/local/bin/chef-deploy" do
  source "chef-deploy.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(:appnames => node['appnames'])
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


