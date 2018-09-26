# 
# Cookbook Name:: zookeeper
# Recipe:: default
#
# Copyright 2015, Promethean
#
# All Rights Reserved - Do Not Redistribute
#

include_recipe "prom-default::default"

service "zookeeper" do 
  supports :start => true, :stop => true, :restart => true
  action :nothing
end

package "zookeeper" do
  version node['zookeeper']['version']
  action :install
end

# Set up search for zookeeper nodes

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search.  Chef Solo does not support search.")
else
  zookeeper_nodes = Array.new
  unless node.chef_environment.include?("local")
    include_recipe "prom-presearch::default"
    $presearch_node['zookeeper_cluster'].each do |zookeeper_node|
      zookeeper_nodes << zookeeper_node
    end
  else
    zookeeper_nodes << "localhost"
  end
    zookeeper_nodes = zookeeper_nodes.sort!
end

template "/etc/zookeeper/zoo.cfg" do
  source "zoo.cfg.erb"
  owner  "zookeeper"
  group  "zookeeper"
  mode   "0644"
  variables( :zknodes => zookeeper_nodes )
  notifies :restart, "service[zookeeper]"
end

template "/var/lib/zookeeper/myid" do
  source "zookeeper.id.erb"
  owner  "zookeeper"
  group  "zookeeper"
  mode   "0644"
  notifies :restart, "service[zookeeper]"
end

template "/etc/zookeeper/java.env" do
  source "java.env.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[zookeeper]"
end

# Set up hostsfile entries for zookeeper nodes
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search.  Chef solo does not support search.")
elsif node.chef_environment.include?("local")
  Chef::Log.warn("This server is a local environment.  Localhost only.")
else
  include_recipe "prom-presearch::default"
  $presearch_node['zookeeper_cluster'].each do |zookeeper_node|
    hostsfile_entry zookeeper_node['ipaddress'] do
      hostname zookeeper_node['hostname']
      comment "Updated by Chef"
      action :create
      unique true
      only_if { node['serveraddress'].nil? || node['serveraddress'].empty? }
    end
  end
end

service "zookeeper" do
  supports :start => true, :stop => true, :restart => true
  action [:start,:enable]
end

