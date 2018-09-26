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

aws = data_bag_item("aws-sdk", "main")

# Add storage for android sftp container data
unless node['android_data_volume'].nil? || node['android_data_volume'].empty?
  # Create and attach aws ebs volume
  node['android_data_volume'].each do |device, size|
    aws_ebs_volume `hostname`.strip! + "-android_ota_data_vol" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size size
      region node['aws_node_region'] if node['requires_aws_region']
      device device
      action [ :create, :attach ]
      only_if { node['provider'] == 'aws' }
    end
  end
end

# Add mount for android sftp data containment of container data
node["android_data_mount"].each do |mount, device|
  directory mount do
    mode '0777'  # Full permission required for primary sftp directory
    action :create
  end
  bash "Running mkfs.ext4 on device: #{device}" do
    __command = "mkfs.ext4 #{device}"
    __fs_check = 'dumpe2fs'
    code __command
    not_if "#{__fs_check} #{device}"
  end
  mount mount do
    device device
    fstype "ext4"
    options "noatime"
    action [:enable, :mount]
  end
end
