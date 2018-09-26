#
# Cookbook Name:: prom-classfront
# Recipe:: afmanagerfront
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-presearch::default"

###############################################################################
##                      Foundation-Manager Split if Necessary                ##  
afmanagerworkers = []
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  unless node.chef_environment.include?("local")
    # Since we are not in a local environment, let's search for foundation only nodes
    $presearch_node['afmanager_nodes'].each do |worker|
      afmanagerworkers << worker
    end
  else
    # In this section, we assume the environment is local so splitting is unnecessary
    search(:node, "role:backend AND name:#{node['hostname']}").each do |worker|
      afmanagerworkers << worker
    end
  end
end
#############################################################################
afmanagernodes = []
afmanagerworkers.each do |worker|
  afmanagernodes << worker['ipaddress']
end
afmanagernodes=afmanagernodes.uniq.sort.join(",")

afmanagerworkers.uniq! { |a| a.ipaddress }
afmanagerworkers.sort! { |a,b| a.ipaddress <=> b.ipaddress }

# Create afmanager http proxy
template "/etc/httpd/conf.d/afmanager.proxy" do
  source "afmanager.proxy.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
  variables(:afmanagerworkers => afmanagerworkers)
  not_if {afmanagerworkers.nil? || afmanagerworkers.empty?}
end
###########################################################

