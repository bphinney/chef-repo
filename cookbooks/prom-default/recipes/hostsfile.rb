#
# Cookbook Name:: prom-default
# Recipe:: hostsfile
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
#

unless node['serveraddress'].nil? || node['serveraddress'].empty?
  hostsfile_entry node['serveraddress'] do
    hostname node['hostname']
    comment "Updated by Chef"
    action :create
    unique true
  end
else
  hostsfile_entry node['ipaddress'] do
    hostname node['hostname']
    comment "Updated by Chef"
    action :create
    unique true
  end
end
