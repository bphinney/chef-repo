#
# Cookbook Name:: logstash
# Recipe:: logstashserver
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'
include_recipe 'prom-default::selinux'
include_recipe 'java::openjdk'
include_recipe 'prom-logstash::logstash-apache'

service 'logstash' do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

yum_package 'logstash' do
  version "#{node['logstash']['version']}"
  action :install
end

%w{output_elasticsearch.conf input_redis.conf filter_grok.conf}.each do |template|
  template "/etc/logstash/conf.d/#{template}" do
    source "#{template}.erb"
    mode   '0644'
    owner  'logstash'
    group  'logstash'
    notifies :restart, 'service[logstash]'
  end
end

file "/etc/logstash/conf.d/filter_multiline.conf" do
  action :delete
end

directory '/etc/logstash/patterns' do
  owner  'logstash'
  group  'logstash'
  recursive true
  action :create
end

cookbook_file '/etc/logstash/patterns/grok-patterns' do
  source 'grok-patterns'
  owner  'logstash'
  group  'logstash'
  mode   '0644'
  notifies :restart, 'service[logstash]'
end

template '/etc/sysconfig/logstash' do
  source 'sysconfig-logstash.erb'
  owner  'root'
  group  'root'
  mode   '0644'
end

template '/etc/init.d/logstash' do
  source 'logstash-init.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

# aws components
include_recipe "prom-logstash::logstash-elb"

include_recipe "prom-logstash::logstash-tools"

service "logstash" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:start, :enable]
end
