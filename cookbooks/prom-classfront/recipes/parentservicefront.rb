#
# Cookbook Name:: prom-parentservice
# Recipe:: parentservicefront
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-presearch::default'
include_recipe 'prom-classfront::netcheck'

#######################################################################
parentserviceworkers = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef solo does not support search.')
else
  unless node.chef_environment.include?('local')
    # Since we are not in a local environment, let's search for foundation only nodes
    $presearch_node['activfoundation_nodes'].each do |worker|
      parentserviceworkers << worker
    end
  else
    # In this section, we assume the environment is local so splitting is unnecessary
    search(:node, "role:backend AND name:#{node['hostname']}").each do |worker|
      parentserviceworkers << worker
    end
  end
end
#########################################################################

parentservicenodes = []
parentserviceworkers.each do |worker|
  parentservicenodes << worker['ipaddress']
end
parentservicenodes = parentservicenodes.uniq.sort.join(',')

parentserviceworkers.uniq! { |a| a.ipaddress }
parentserviceworkers.sort! { |a, b| a.ipaddress <=> b.ipaddress }

# Create parentservice http proxy
template '/etc/httpd/conf.d/parent-service.proxy' do
  source 'parent-service.proxy.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, "execute[configcheck]"
  variables(:parentserviceworkers => parentserviceworkers)
  not_if { parentserviceworkers.nil? || parentserviceworkers.empty? }
end
###########################################################
