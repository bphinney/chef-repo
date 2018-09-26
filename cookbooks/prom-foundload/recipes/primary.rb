#
# Cookbook Name:: prom-foundload
# Recipe:: primary
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

floadprimary = []
search(:node, "foundation-load:*primary* AND chef_environment:#{node.chef_environment}").each do |server|
  floadprimary << server
end 
if floadprimary.nil? || floadprimary.empty?
  node.set['foundation-load'] = "primary"
end
