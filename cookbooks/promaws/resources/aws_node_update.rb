#
#  Cookbook Name:: promaws
#  Provider:: node_update
#
#  Copyright 2016, Promethean
#
#  All rights reserved - Do Not Redistribute
#
#  Provider updates aws data to the node
# 
#  Use:
#
#  aws_node_update 'default' do
#    action :update
#  end
#

resource_name :aws_node_update

actions :update, :force
default_action :update

action_class do
  def whyrun_supported?
    true
  end
end


include Promaws::Helpers
include Promaws::Apiconnect

# Action updates node at end of chef-client run
action :update do
  if !node['provider'] == 'aws'
    Chef::Log.info "Node is not Aws, bypassing node data update"
  else
    converge_by("Write Aws instance data to node record") do
      update_aws_node('normal')
    end
  end
end

# Action updates node persistently at runtime
# This overrides both a run_list override or chef-client failure
action :force do
  if !node['provider'] == 'aws'
    Chef::Log.info "Node is not Aws, bypassing node force update"
  else
    converge_by("WARN: Forcing persistent save of Aws instance data to node") do
      update_aws_node('force')
    end
  end
end

# Method extracts pertinent information from available Aws apis
# and updates node record persistently for later use
def update_aws_node(update = 'normal')
  ec2         = aws_api_connect('EC2_Client')
  instance_id = lookup_instance_id

  # List of availability zones available to the instance
  zone_array = []
  instance_region = ""
  av_zones = ec2.describe_availability_zones
  av_zones['availability_zones'].each do |zone|
    zone_array << zone['zone_name']
  end
  # Region of the instance
  # Region is automatically provided as part of availability zone
  local_region = av_zones['availability_zones'][0]['region_name']

  # List of regions available to the instance
  region_array = []
  regions = ec2.describe_regions
  regions['regions'].each do |region|
    region_array << region['region_name']
  end

  # Availability zone of the instance
  instance_array = []
  instances = ec2.describe_instances({
    instance_ids: ["#{instance_id}"],
  })
  av_zone = instances['reservations'][0]['instances'][0]['placement']['availability_zone']

  # IN-1451 - instance_id is been moved to ec2 attribute namespace per v3.1.3 cookbook.
  node.normal['ec2']['instance_id'] = instance_id

  node.normal['aws']['instance_id'] = instance_id
  node.normal['aws']['av_zones']    = zone_array
  node.normal['aws']['region']      = local_region
  node.normal['aws']['regions']     = region_array
  node.normal['aws']['av_zone']     = av_zone

  if update == 'force'
    node.save
  end
end
