#
# Cookbook Name:: atlassian
# Recipe:: hostsfile
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#

hostsfile_entry node['ipaddress'] do
  hostname node['hostname']
  comment "Updated by Chef"
  action :create
  unique true
end

#if Chef::Config[:solo] and not chef_solo_search_installed?
#  Chef::Log.warn("This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.")
#else
#  %w{bamboo confluence jira stash}.each do |app|
#    search(:node, "recipes:atlassian\\:\\:#{app}").each do |server|
#      hostsfile_entry server['ipaddress'] do
#        hostname "#{app}.prometheanjira.com"
#        comment "Updated automatically by Chef"
#        action :append
#      end
#    end
#  end
#end

