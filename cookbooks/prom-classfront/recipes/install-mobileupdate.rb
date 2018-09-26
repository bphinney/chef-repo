#
# Cookbook Name:: prom-classfront
# Recipe:: install-mobileupdate
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
mobileupdate_version = node['applications']['frontend']['mobileupdate_version']

directory "/opt/www/current" do
  recursive true
  owner "apache"
  group "apache"
  action :create
end
template "/etc/httpd/conf.d/mobileupdate.conf" do
  source "mobileupdate.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end
package "mobileupdate" do
  version mobileupdate_version
  action :install
  allow_downgrade true
  not_if { mobileupdate_version == '0.0.0-1' }
end
