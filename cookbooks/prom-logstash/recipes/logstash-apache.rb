#
# Cookbook Name:: prom-logstash
# Recipe:: logstash-apache
#
# Copyright 2016, Promethean
# All rights reserved -Do not Redistribute
#

# Performs default http actions
include_recipe 'prom-http::default'

service 'httpd' do
  supports stop: true, start: true, restart: true, status: true, reload: true
  if node['platform_version'].to_i == '7'
    stop_command '/bin/systemctl stop httpd'
    start_command '/bin/systemctl start httpd'
    reload_command '/usr/sbin/apachectl graceful'
    restart_command '/bin/systemctl restart httpd'
  else
    stop_command  '/etc/init.d/httpd stop'
    start_command '/etc/init.d/httpd start'
    reload_command '/etc/init.d/httpd graceful'
    restart_command '/etc/init.d/httpd restart'
  end
  action :nothing
end

execute 'configcheck' do
  command 'apachectl configtest'
  action  :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

template '/etc/httpd/conf.d/logstash-kibana.conf' do
  source 'logstash-kibana.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, 'execute[configcheck]'
end

template '/etc/httpd/conf.d/logstash-kibana.proxy' do
  source 'logstash-kibana.proxy.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, 'execute[configcheck]'
end

cron 'update_htaccess' do
  command 'chef-client -o prom-http::update_htaccess > /var/log/update_htaccess.log 2>&1'
  minute  '*/15'
  hour    '*'
  action  :create
  notifies :run, 'execute[configcheck]'
end
