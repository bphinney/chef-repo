#
# Cookbook Name:: glusterfs
# Recipe:: nfs-server
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Install Snapshots for backups
promaws_ebssnap "glusterfs" do
  frequency "daily"
  retention 4
  action    :enable
  only_if { node["provider"] == "aws" && node['nfs-server'] == "primary" }
end

  
