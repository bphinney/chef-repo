#
# Cookbook Name:: prom-default
# Recipe:: yumcache
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

execute "yumcache" do
  command "yum makecache"
  action :run
  not_if { node['yum']['cache_clean'] == "false" }
end
