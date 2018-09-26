#
# Cookbook Name:: prom-classfront
# Recipe:: maintenance
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

service 'httpd' do
  if node['platform_version'].to_i == '7'
    stop_command '/usr/bin/systemctl stop httpd'
    start_command '/usr/bin/systemctl start httpd'
    reload_command '/usr/sbin/apachectl graceful'
    restart_command '/usr/bin/systemctl restart httpd'
  else
    stop_command  '/etc/init.d/httpd stop'
    start_command '/etc/init.d/httpd start'
    reload_command '/etc/init.d/httpd graceful'
    restart_command '/etc/init.d/httpd restart'
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :reload => true, :graceful => true
  action :nothing
end

execute 'configcheck' do
  command 'apachectl configtest'
  action :nothing
  notifies :"#{node['apache']['changetype']}", 'service[httpd]'
end

directory '/opt/www/maintenance' do
  recursive true
  owner 'apache'
  group 'apache'
  action :create
end

template '/etc/httpd/conf.d/maintenance.redirect' do
  source 'maintenance.redirect.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, 'execute[configcheck]'
end

maintenance_version = node['applications']['frontend']['maintenance_version']

yum_package 'maintenance' do
  version maintenance_version
  action :install
  allow_downgrade true
  not_if { maintenance_version == '0.0.0-1' }
end
