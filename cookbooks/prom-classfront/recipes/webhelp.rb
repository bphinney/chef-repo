#
# Cookbook Name:: prom-classfront
# Recipe:: webhelp
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"

webhelp_version = node['applications']['frontend']['webhelp_version']

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.default['newrelic']['application_monitoring']['app_name'] = "webhelp"
end

# Include default http activities
include_recipe "prom-http::default"

# Include the mod_security framework
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

directory "/opt/www/webhelp" do
  recursive true
end

yum_package "webhelp" do
  version webhelp_version
  action :install
  allow_downgrade true
  not_if { webhelp_version == '0.0.0-1' }
  notifies :run, "execute[configcheck]"
end

template "/etc/httpd/conf.d/webhelp.conf" do
  source "webhelp.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  unless node['webhelp']['webhelp_install'] == "false"
  action :create
  else
  action :delete
  end
  notifies :run, "execute[configcheck]"
end
