#
# Cookbook Name:: prworld
# Recipe:: prworld-snap
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Install Snapshots for backups
if node["dotcms"].attribute?("backup_active") && node["dotcms"]["backup_active"] == "true"
  promaws_ebssnap "prworld-snapshot" do
    frequency "weekly"
    retention 2
    action :enable
    only_if { node["provider"] == "aws" }
  end
end 
