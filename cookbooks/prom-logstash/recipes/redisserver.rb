#
# Cookbook Name:: prom-logstash
# Recipe:: redisserver
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
#

include_recipe 'prom-default'
include_recipe 'prom-default::selinux'
include_recipe 'prom-default::repo'

service 'redis' do
  supports :start => true, :stop => true, :restart => true
  action :nothing
end

package 'redis' do
  action :upgrade
end

directory '/var/log/redis' do
  owner 'redis'
  group 'root'
  mode  '0755'
end

directory '/opt/redis2/data' do
  owner 'redis'
  group 'root'
  mode  '0755'
  action :create
  recursive true
end

template '/etc/redis.conf' do
  source 'redis.conf.erb'
  owner  'root'
  group  'root'
  notifies :restart, 'service[redis]'
end

# Adding these entries as a desired level, but on local, probably don't need them  
execute 'sysctl_reload' do
  command 'sysctl -p'
  returns [0,255]
  action :nothing
end

entries = ['vm.overcommit_memory=1','fs.file-max=100000','net.core.somaxconn=65535']
entries.each do |entry|
  append_if_no_line entry do
    path '/etc/sysctl.conf'
    line entry
    notifies :run, 'execute[sysctl_reload]'
  end
end

service 'redis' do
  supports :start => true, :stop => true, :restart => true
  action [:start,:enable]
end

