#
# Cookbook Name:: prom-default
# Recipe:: hostsfile_update
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#
#if Chef::Config[:solo]
#  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
#else
unless Chef::Config[:solo]
  include_recipe "prom-presearch"
  $presearch_node['rabbitmq_cluster'].each do |rabbitnode|
    hostsfile_entry rabbitnode['ipaddress'] do
      hostname rabbitnode['hostname']
      comment "Updated by Chef"
      action :create
      unique true
      not_if { node.chef_environment.include?("local") }
      only_if { File.exists?('/usr/sbin/rabbitmqctl') }
    end
  end
  $presearch_node['datacenter_nodes'].each do |datacenternode|
    hostsfile_entry datacenternode['ipaddress'] do
      hostname datacenternode['hostname']
      comment "Updated by Chef"
      action :create
      unique true
      only_if { File.exists?('/opt/opscode/bin/chef-server-ctl') || File.exists?('/opt/provisioner/chef_tenant_provision') || File.exists?('/usr/sbin/nagios') || node.run_list.roles.include?("jumpbox") }
    end
  end
  hostsfile_entry node['ipaddress'] do
    hostname node['hostname']
    comment "Updated by Chef"
    action :create
    unique true
    only_if { node['serveraddress'].nil? || node['serveraddress'].empty? }
  end
  $presearch_node['nfs_servers'].each do |server|
    hostsfile_entry server['ipaddress'] do
      hostname server['hostname']
      action :create
      unique true
      not_if { node.chef_environment.include?("local|load") }
     end
  end
end
