#
# Cookbook Name:: prom-classfront
# Recipe:: install-uiadmin
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
if node['applications'].attribute?('frontend') and 
 node['applications']['frontend'].attribute?('uiadmin_version')
  uiadmin_version = node['applications']['frontend']['uiadmin_version']
else
  uiadmin_version = node['applications']['uiadmin_version']
end

###<-Install UI-Admin Screens for /management
directory "/opt/www/management" do
  recursive true
  owner "apache"
  group "apache"
  action :create
end
template "/etc/httpd/conf.d/uiadmin.conf" do
  source "uiadmin.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end
package "uiadmin" do
  version uiadmin_version
  action :install
  allow_downgrade true
  not_if { uiadmin_version == '0.0.0-1' }
end
