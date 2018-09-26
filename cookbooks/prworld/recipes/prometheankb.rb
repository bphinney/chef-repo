#
# Cookbook Name:: prworld
# Recipe:: prometheankb
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.default['newrelic']['application_monitoring']['app_name'] = "prometheankb"
end

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

directory "/opt/www/prometheankb" do
  recursive true
end

unless node['applications'].attribute?('cmsplugin') && node['applications']['cmsplugin'].attribute?('prometheankb_version')
  prometheankb_version = node['applications']['prometheankb_version']
else
  prometheankb_version = node['applications']['cmsplugin']['prometheankb_version']
end

yum_package "prometheankb" do
  version prometheankb_version
  action :install
  allow_downgrade true
  not_if { prometheankb_version == '0.0.0-1' }
  notifies :run, "execute[configcheck]"
end

template "/etc/httpd/conf.d/prometheankb.conf" do
  source "prometheankb.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end
