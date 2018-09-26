#
# Cookbook Name:: prom-classfront
# Recipe:: netcheck
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

directory "/opt/www/netcheck" do
  recursive true
  owner "apache"
  group "apache"
  action :create
end

yum_package "netcheck" do
  action :upgrade
end

