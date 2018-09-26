#
# Cookbook Name:: prom-sftp
# Recipe:: sftp-server-vol
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

# aws components
include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")

# Add storage for sftp container data 
unless node['sftp_data_volume'].nil? || node['sftp_data_volume'].empty?
  # Create and attach aws ebs volume
  node['sftp_data_volume'].each do |device, size|
    aws_ebs_volume `hostname`.strip! + "-sftp_data_vol" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size size
      device device
      region node['aws_node_region'] if node['requires_aws_region']
      action [ :create, :attach ]
      only_if { node['provider'] == 'aws' }
    end
  end
end

# Add mount for sftp data containment of container data
node["sftp_data_mount"].each do |mount, device|
  directory mount do; action :create; end
  bash "Running mkfs.ext4 on device: #{device}" do
    __command = "mkfs.ext4 #{device}"; __fs_check = 'dumpe2fs'
    code __command
    not_if "#{__fs_check} #{device}"
  end

  mount mount do
    device device; fstype "ext4"; options "noatime"
    action [:enable, :mount]
  end
end
