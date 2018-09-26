#
# Cookbook Name:: prom-chef
# Recipe:: db-management
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"

package "percona-toolkit" do
  version "2.2.16-1"
  action :install
end

package "MySQL-client" do
  action :upgrade
end
