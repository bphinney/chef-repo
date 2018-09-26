#
# Cookbook Name:: haproxy
# Recipe:: default
#
# Copyright 2013, Promethean, Inc
#
# All rights reserved - Do Not Redistribute
#

service "haproxy" do
  supports :start => true, :stop => true, :restart => true, :status => true, :reload => true
  action :nothing
end

package "haproxy" do
  :upgrade
end

directory "/etc/haproxy/errors" do
  owner "haproxy"
  group "haproxy"
  recursive true
  action :create
end

file "/etc/haproxy/errors/503.http" do
  owner "haproxy"
  group "haproxy"
  mode "0644"
  action :create
end

service "haproxy" do
  supports :start => true, :stop => true, :restart => true, :status => true, :reload => true
  action [:enable,:start]
end

