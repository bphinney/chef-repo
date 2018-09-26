#
# Cookbook Name:: prom-default
# Recipe:: chefclient-update
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

cron "chef-client-update" do
  command "/usr/bin/chef-client -o omnibus_updater > /var/log/chef/chef-client-update.log 2>&1"
  minute "30"
  hour   "4"
  action :create
end
