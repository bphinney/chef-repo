#
# Cookbook Name:: prom-elasticsearch
# Recipe:: elasticsearchebs
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"

# Construct elasticsearch ebs volumes based on data bag volume definitions

include_recipe 'promaws::default'
aws = data_bag_item('aws-sdk', 'main')
node.elasticsearch['data']['devices'].each do |device,params|
  # Create and attach elasticsearch ebs volumes
  Chef::Log.info("Attaching device #{device} with size #{params['ebs']['size']}GB")
  aws_ebs_volume `hostname`.strip! + "-gfs_vol" do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    size params['ebs']['size']
    device device
    volume_type "gp2"
    action [ :create, :attach ]
    region node['aws_node_region'] if node['requires_aws_region']
    only_if { node['provider'] == 'aws' }
  end
end

# Install Snapshots for backups
promaws_ebssnap 'elb-server' do
  frequency 'weekly'
  retention 2
  action :enable
  only_if { node['provider'] == 'aws' }
end

package "xfsprogs" do; action :install; end
package "bc" do; action :install; end

# Mounting and formatting is done via the elasticsearch::data recipe
