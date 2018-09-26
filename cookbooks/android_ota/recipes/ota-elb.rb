#
# Cookbook Name:: android_ota
# Recipe:: default
#
# Copyright 2016, Promethean, Inc
#
# All rights reserved - Do Not Redistribute
#
# Initial installations for ota updater 
#
elb_name   = node['android_ota']['sftp_elbname']

include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")

# Enforce minimum default elbname
unless elb_name.nil? || elb_name.empty?
  node.default['elbname'] = elb_name
end

# Register android_ota to appropriate aws elb
aws_elastic_lb "#{node['elbname']}" do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  name node['elbname']
  region node['aws_node_region'] if node['requires_aws_region']
  action :register
  only_if { node['provider'] == 'aws' }
end
