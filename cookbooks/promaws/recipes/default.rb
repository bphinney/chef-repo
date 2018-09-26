#
# Cookbook Name:: promaws
# Recipe:: default
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'promaws::self-aware'

if node['provider'] == 'aws'
  # Access AWS Credentials
  aws = data_bag_item('aws-sdk', 'main')
  include_recipe 'prom-default::geminsecure'
  include_recipe 'aws'

  # Extends Helpers library to all recipes
  Chef::Recipe.include Promaws::Helpers

  # Ensure modules/gems are loaded (>= Aws cookbook 3.3.2)
  if aws_cookbook_version >= '3.3.2'
    Chef::Recipe.include Opscode::Aws
    require_aws_sdk
  end

  # Set a default region if there is no node record yet
  if node['aws']['instance_id'].nil?
    node.normal['aws']['instance_id'] = instance_region
  end

  # ensures ec2 instance definition exists for Aws cookbook
  node.default['ec2']['instance_id'] = node['aws']['instance_id']

  # IN-1451 - Set defaults for Aws cookbook update
  node.default['aws_node_region'] = instance_region
  node.default['requires_aws_region'] = requires_region

  # Writes Aws instance data to the node record
  promaws_node_update 'default' do
    action :update
  end
end



