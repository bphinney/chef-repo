#
# Cookbook Name:: prom-collabserver
# Recipe:: activvertx-remove
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

service 'collabserver' do
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

package "activvertx" do
  action :remove
  notifies :restart, "service[collabserver]"
end
