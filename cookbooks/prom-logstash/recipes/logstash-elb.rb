#
# Cookbook Name:: logstash
# Recipe:: logstashserver
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

# aws components
include_recipe 'promaws::default'
aws = data_bag_item('aws-sdk', 'main')

# Allow for optional attribute-based elbname
if node['logstash'].attribute?('logstash_elbname')
  node.default['elbname'] = node['logstash']['logstash_elbname']
else
  node.default['elbname'] = node.name
end

# Register Logstash server to appropriate aws elb
aws_elastic_lb "#{node['elbname']}" do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  name node['elbname']
  action :register
  region node['aws_node_region'] if node['requires_aws_region']
  only_if { node['provider'] == 'aws' }
end
