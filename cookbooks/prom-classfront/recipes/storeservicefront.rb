#
# Cookbook Name:: prom-classfront
# Recipe:: storeservicefront
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-presearch::default'
include_recipe 'prom-classfront::netcheck'

#######################################################################
storeserviceworkers = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef solo does not support search.')
else
  unless node.chef_environment.include?('local')
    # Since we are not in a local environment, let's search for storeservice only nodes
    $presearch_node['storeservice_nodes'].each do |worker|
      storeserviceworkers << worker
    end
  else
    # In this section, we assume the environment is local so splitting is unnecessary
    search(:node, "role:authserver AND name:#{node['hostname']}").each do |worker|
      storeserviceworkers << worker
    end
  end
end
#########################################################################

storeservicenodes = []
storeserviceworkers.each do |worker|
  storeservicenodes << worker['ipaddress']
end
storeservicenodes = storeservicenodes.uniq.sort.join(',')

storeserviceworkers.uniq! { |a| a.ipaddress }
storeserviceworkers.sort! { |a, b| a.ipaddress <=> b.ipaddress }

# Create storeservice http proxy
template '/etc/httpd/conf.d/store-service.proxy' do
  source 'store-service.proxy.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, "execute[configcheck]"
  variables(:storeserviceworkers => storeserviceworkers)
  not_if { storeserviceworkers.nil? || storeserviceworkers.empty? }
end
###########################################################
