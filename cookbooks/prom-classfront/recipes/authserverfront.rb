#
# Cookbook Name:: prom-authserver
# Recipe:: authfront
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-presearch::default'

#######################################################################
##                      Authserver Split if Necessary                ##
authserverworkers = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef solo does not support search.')
else
  unless node.chef_environment.include?('local')
    # Since we are not in a local environment, let's search for foundation only nodes
    $presearch_node['authserver_nodes'].each do |worker|
      authserverworkers << worker
    end
  else
    # In this section, we assume the environment is local so splitting is unnecessary
    search(:node, "role:authserver AND name:#{node['hostname']}").each do |worker|
      authserverworkers << worker
    end
  end
end
#########################################################################

authservernodes = []
authserverworkers.each do |worker|
  authservernodes << worker['ipaddress']
end
authservernodes = authservernodes.uniq.sort.join(',')

authserverworkers.uniq! { |a| a.ipaddress }
authserverworkers.sort! { |a, b| a.ipaddress <=> b.ipaddress }

# Create authserver http proxy
template '/etc/httpd/conf.d/authserver.proxy' do
  source 'authserver.proxy.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, 'execute[configcheck]'
  variables(:authserverworkers => authserverworkers)
  not_if { authserverworkers.nil? || authserverworkers.empty? }
end
###########################################################
