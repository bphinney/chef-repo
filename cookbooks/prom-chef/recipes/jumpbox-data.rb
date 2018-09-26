#
# Cookbook Name:: prom-chef
# Recipe:: jumpbox-data
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-chef::chef-api-gem"

# Java Dev Jumpbox Management (wherever the appropriate data structure exists)
template "/usr/bin/jumpbox_dataload.rb" do
  source "jumpbox_dataload.rb.erb"
  owner  "root"
  group  "root"
  mode   "0750"
end

cron "load_jumpbox_data" do
  command "/usr/bin/jumpbox_dataload.rb > /dev/null 2>&1"
  minute "5"
  hour "*"
end
