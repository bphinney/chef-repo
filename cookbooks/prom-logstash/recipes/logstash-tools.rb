#
# Cookbook Name:: logstash
# Recipe:: logstashclean
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

template '/etc/cron.daily/logstash-clean' do
  source 'logrotate-logstash.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

#IN-1285 Adding cron entry for plugin updates
cron 'logstash_plugin_update' do
  command '/usr/bin/chef-client -o prom-logstash::logstashplugin-update > /var/log/logstashplugin-update.log 2>&1'
  minute  '15'
  hour    '3'
  weekday '0'
  action :delete
end

template '/etc/yum.repos.d/curator.repo' do
  source 'curator.repo.erb'
  owner  'root'
  group  'root'
  mode   '0644'
end

package 'elastic-curator' do
  action :upgrade
end

cron 'logs_delete' do
  command "/usr/bin/curator --host #{node['kibana']['es_server']} --port #{node['kibana']['es_port']} delete --older-than 30 > /var/log/esindex-clean.log 2>&1"
  minute '30'
  hour   '0'
  action :create
end
