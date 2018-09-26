#
# Cookbook Name:: prworld
# Recipe:: prmaintenance
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#


service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl graceful"
    restart_command "/usr/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :reload => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

directory "/opt/www/prmaintenance" do
  recursive true
  owner "apache"
  group "apache"
  action :create
end

template "/etc/httpd/conf.d/prmaintenance.redirect" do
  source "prmaintenance.redirect.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end

unless node['applications'].attribute?('cmsplugin') && node['applications']['cmsplugin'].attribute?('prmaint_version')
  prmaintenance_version = node['applications']['prmaint_version']
else
  prmaintenance_version = node['applications']['cmsplugin']['prmaint_version']
end

yum_package "prmaintenance" do
  version prmaintenance_version
  action :install
  allow_downgrade true
  not_if { prmaintenance_version == '0.0.0-1' }
end
