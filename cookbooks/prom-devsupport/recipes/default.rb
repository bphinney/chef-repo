#
# Cookbook Name:: prom-devsupport
# Recipe:: default
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"
include_recipe "prom-default::selinux"
include_recipe "prom-http::default"

#Create tomcat user and home directory for devkeys
group "tomcat" do
  action :create
  gid "496"
end

user "tomcat" do
  comment "Tomcat user account"
  uid '495'
  gid 'tomcat'
  home '/home/tomcat'
  shell '/bin/bash'
end

#include_recipe "prom-default::devkeys"

directory "/opt/tomcat/logs" do
  recursive true
  owner "tomcat"
  group "tomcat"
end

# redmon installation
#gem_package "redmon" do
#  action :upgrade
#end

# Redis commander is a nodejs application
%w{nodejs npm}.each do |package|
  package package do
  end
end

service "redis-commander" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:start, :enable]
end

# Config dotfile will cache old settings unless removed
# It will be recreated on service restart
execute "clear_config" do
  command "rm -f /home/tomcat/.redis-commander"
  action    :nothing
  notifies  :restart, "service[redis-commander]"
end

#Install redis-commander if it is not installed
execute "redis-commander-install" do
  command "npm install -g redis-commander"
  not_if  "test -f /usr/bin/redis-commander"
end

template "/etc/init.d/redis-commander" do
  source "redis-commander-init.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(
    :redis_host => node['elasticache']['server'],
    :redis_port => node['elasticache']['port']
  )
  notifies :run, "execute[clear_config]"
end

#Install configurations for apache proxy to redis-commander
template "/etc/httpd/conf.d/rcommander.conf" do
  source "rcommander.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end

template "/etc/httpd/conf.d/.digest_pw" do
  source "digestpw.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end

# Register to the Sharing Web Elastic Loab Balancer
if node["provider"] == "aws"
  include_recipe "promaws"
  aws = data_bag_item("aws-sdk", "main")
  unless node['devsupport']['devsupport_elb'].nil? || node['devsupport']['devsupport_elb'].empty?
    node.default['elbname'] = node['devsupport']['devsupport_elb']
    aws_elastic_lb "#{node['elbname']}" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      name node['elbname']
      region node['aws_node_region'] if node['requires_aws_region']
      action :register
    end
  end
end
