#
# Cookbook Name:: prom-default
# Recipe:: geminsecure
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

Chef::Log::info("Gem insecure set to #{node['chef']['allow_insecure']}")
template "/root/.gemrc" do
  source "gemrc.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  action :create
  only_if { node['chef']['allow_insecure'] == "true" }
end

