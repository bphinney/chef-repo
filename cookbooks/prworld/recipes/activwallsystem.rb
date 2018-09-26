#
# Cookbook Name:: prworld
# Recipe:: activwallsystem
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"

# Perform default http actions
include_recipe "prom-http::default"
# Perform default mod_security actions
include_recipe "prom-http::mod_security"

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

directory "/opt/www/activwallsystem" do
  recursive true
end


unless node['applications'].attribute?('cmsplugin') && node['applications']['cmsplugin'].attribute?('activwallsystem_version')
  activwallsystem_version = node['applications']['activwallsystem_version']
else
  activwallsystem_version = node['applications']['cmsplugin']['activwallsystem_version']
end

yum_package "activwallsystem" do
  version activwallsystem_version
  action :install
  allow_downgrade true
  not_if { activwallsystem_version == '0.0.0-1' }
  notifies :run, "execute[configcheck]"
end

template "/etc/httpd/conf.d/activwallsystem.conf" do
  source "activwallsystem.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end
