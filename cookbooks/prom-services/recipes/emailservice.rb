#
# Cookbook Name:: promethean
# Recipe:: emailservice
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

#include_recipe "java::openjdk"
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "yum::default"

service "emailsrv" do
  if node['platform_version'].to_i == '7'
    start_command="/opt/tools/emailservice/emailsrv start"
    stop_command="/opt/tools/emailservice/emailsrv stop"
    reload_command="/opt/tools/emailservice/emailsrv reload"
    restart_command="/opt/tools/emailservice/emailsrv restart"
  end
  only_if { File.exist?("/opt/tools/emailservice/emailsrv")}
  supports :stop => true, :start => true, :restart => true, :status => true, :enable => true
  action :nothing
end

gem_package "sinatra" do
  action :install
end

package "bind-utils" do
  action :upgrade
end

emailservice_version = node['applications']['tools']['emailservice_version']

package "emailservice" do
  version emailservice_version
  action :install
  not_if { emailservice_version == '0.0.0-1' }
  notifies :restart, "service[emailsrv]"
end

link "/etc/rc.d/init.d/emailsrv" do
  to "/opt/tools/emailservice/emailsrv"
  notifies :enable, "service[emailsrv]"
  only_if { File.exist?("/opt/tools/emailservice/emailsrv") && node['platform_version'].to_i != '7' }
end

if node["provider"] == "aws"
  #aws cookbook
  include_recipe "promaws::default"
  aws = data_bag_item("aws-sdk", "main")

  aws_elastic_lb "#{node['email']['emailservice_elb']}" do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    name node['email']['emailservice_elb']
    action :register
    region node['aws_node_region'] if node['requires_aws_region']
    not_if { emailservice_version == '0.0.0-1' }
  end
end

