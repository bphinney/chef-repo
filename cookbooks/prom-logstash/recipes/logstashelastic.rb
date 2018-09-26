#
# Cookbook Name:: logstash
# Recipe:: logstashelastic
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"
include_recipe "java::openjdk"

# Add storage for backup logstash client based data
if node["provider"] == "aws"
  include_recipe "promaws::default"
  aws = data_bag_item("aws-sdk", "main")
  if node['provider'] == "aws"
  # Create and attach volume
    aws_ebs_volume `hostname`.strip! + "-logstash_bkup_vol" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size node['elasticsearch']['backup']['size']
      device node['elasticsearch']['backup']['device']
      region node['aws_node_region'] if node['requires_aws_region']
      action [ :create, :attach ]
    end
  end
end

mountpoints = []
node['elasticsearch']['backup']['mount'].each do |mount,device|
  directory mount do
    action :create
  end
  bash "Format device: #{device}" do
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
  mountpoints << mount
  bkup_vol_name = mount[1..-1];
  template "/usr/local/bin/elastic-backup" do
    source "elastic-backup.erb"
    owner  "root"
    group  "root"
    mode   "0755"
    variables ({
      :logstash_bkup_mount => "#{bkup_vol_name}",
      :days_to_retain_backups => node['elasticsearch']['backup']['days_to_retain']
    })
  end
end

template "/usr/local/bin/elastic-clean" do
  source "elastic-clean.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

cron "elastic-clean" do
  command "/usr/local/bin/elastic-clean > /var/log/elastic-clean 2>&1"
  minute  "10"
  hour    "1"
end

cron "elastic-backup" do
  command "/usr/local/bin/elastic-backup > /var/log/elastic-backup 2>&1"
  minute  "15"
  hour    "1"
end
