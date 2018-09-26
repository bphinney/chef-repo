#
# Cookbook Name:: promethean
# Recipe:: prworldfront
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Register to the prworld Elastic Load Balancer
if node["provider"] == "aws"
  include_recipe "promaws::default"
  aws = data_bag_item("aws-sdk", "main")
  unless node['prworld']['prw_elb'].nil? || node['prworld']['prw_elb'].empty?
    aws_elastic_lb "#{node['prworld']['prw_elb']}" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      name node['prworld']['prw_elb']
      region node['aws_node_region'] if node['requires_aws_region']
      action :register
    end
  end
end

