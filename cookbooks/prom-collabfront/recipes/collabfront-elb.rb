#
# Cookbook Name:: promethean
# Recipe:: collabfront-elb
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")
#aws cookbook
aws_elastic_lb "#{node['collab']['collab_elb']}" do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  name node['collab']['collab_elb']
  region node['aws_node_region'] if node['requires_aws_region']
  action :register
end
