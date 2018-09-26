#
# Cookbook Name:: atlassian-yumrepo
# Recipe:: reposnap
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "promaws"

# Install Snapshots for backups
promaws_ebssnap "reposnap" do
  frequency "daily"
  retention 7
  action :enable
  only_if { "#{node["provider"]}" == "aws" }
end

