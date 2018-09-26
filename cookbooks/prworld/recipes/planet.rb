#
# Cookbook Name:: prworld
# Recipe:: planet
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"

service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl reload"
    restart_command "/usr/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

directory "/opt/www/planet" do
  recursive true
end

unless node['applications'].attribute?('cmsplugin') && node['applications']['cmsplugin'].attribute?('planet_version')
  planet_version = node['applications']['planet_version']
else
  planet_version = node['applications']['cmsplugin']['planet_version']
end
yum_package "planet" do
  version planet_version
  action :install
  allow_downgrade true
  not_if { planet_version == '0.0.0-1' }
  notifies :run, "execute[configcheck]"
end

template "/etc/httpd/conf.d/planet.conf" do
  source "planet.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  action :create
  not_if { planet_version == '0.0.0-1' }
  notifies :run, "execute[configcheck]"
end
