#
# Cookbook Name:: prom-chef
# Recipe:: chefserver-snap
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Install Snapshots for backups
promaws_ebssnap "chef-server" do
  frequency "weekly"
  retention 2
  action    :enable
  only_if { node["provider"] == "aws" }
end
