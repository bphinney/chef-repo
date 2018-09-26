#
# Cookbook Name:: prom-classfront
# Recipe:: classflow-elb
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

  #aws cookbook
include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")

aws_elastic_lb "#{node['apache']['cf_elb']}" do
  aws_access_key aws['aws_access_key_id']
  aws_secret_access_key aws['aws_secret_access_key']
  name node['apache']['cf_elb']
  region node['aws_node_region'] if node['requires_aws_region']
  action :register
end

