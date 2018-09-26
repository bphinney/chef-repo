#
# Cookbook Name:: prom-sftp
# Recipe:: sftp-server
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

# aws components
include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")

# Attributes in the data_bag sftp
begin
  proftpd = data_bag_item("sftp", "proftpd")
rescue Net::HTTPServerException
  Chef::Log.info("No proftpd configuration attribues found in the data bag.")
end

# Enforce minimum default elbname
unless proftpd['sftp_elbname'].nil? || proftpd['sftp_elbname'].empty?
  node.default['elbname'] = proftpd['sftp_elbname'] 
end

# Register sftp-server to appropriate aws elb
aws_elastic_lb "#{node['elbname']}" do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  name node['elbname']
  action :register
  region node['aws_node_region'] if node['requires_aws_region']
  only_if { node['provider'] == 'aws' }
end

