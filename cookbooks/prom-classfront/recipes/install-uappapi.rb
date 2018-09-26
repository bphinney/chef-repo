#
# Cookbook Name:: prom-classfront
# Recipe:: install-uappapi
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

uappapi_version = node['applications']['frontend']['uappapi_version']

directory "/opt/www/uappapi" do
  recursive true
  owner "apache"
  group "apache"
  action :create
end
yum_package "uappapi" do
  version uappapi_version
  action :install
  allow_downgrade true
  not_if { uappapi_version == '0.0.0-1' }
end

template "/etc/httpd/conf.d/uappapi.conf" do
  source "uappapi.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables( :countryblock => node['countryblock'].split(",") )
  action :delete
  notifies :run, "execute[configcheck]"
end

