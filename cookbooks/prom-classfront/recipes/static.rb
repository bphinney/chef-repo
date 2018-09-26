#
# Cookbook Name:: prom-classfront
# Recipe:: static 
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"

service "httpd" do
  supports :stop => true, :start => true, :restart => true, :status => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

directory "/opt/www/static" do
  recursive true
end

static_version = node['applications']['frontend']['static_version']

yum_package "static" do
  version static_version
  action :install
  allow_downgrade true
  not_if { static_version == '0.0.0-1' }
  notifies :run, "execute[configcheck]"
end

template "/etc/httpd/conf.d/static.conf" do
  source "static.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end

cookbook_file "/opt/www/static/favicon.ico" do
  source "favicon.ico"
end

file "/opt/www/static/jquery.min.map" do
  owner  "apache"
  group  "apache"
  mode   "0644"
  action :create_if_missing
end

directory "/opt/www/static/robots/go" do
  recursive true
  action :create
end

directory "/opt/www/static/robots/no" do
  recursive true
  action :create
end

cookbook_file "/opt/www/static/robots/no/robots.txt" do
  source "robots_no.txt"
  owner  "apache"
  group  "apache"
  action :create
end

cookbook_file "/opt/www/static/robots/go/robots.txt" do
 source "robots_go.txt"
  owner  "apache"
  group  "apache"
  action :create
end

