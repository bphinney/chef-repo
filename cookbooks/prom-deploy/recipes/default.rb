#
# Cookbook Name:: prom-deploy
# Recipe:: default
#
# Copyright 2016, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

directory "/opt/tools/deploy" do
  recursive true
end

package "mailx" do
  action :upgrade
end

template "/opt/tools/deploy/shinto-catalina" do
  source "shinto-catalina.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/opt/tools/deploy/shinto-maint" do
  source "shinto-maint.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

include_recipe "prom-mailrelay::mailrelay"
