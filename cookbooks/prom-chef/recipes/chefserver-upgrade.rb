#
# Cookbook Name:: promethean
# Recipe:: chefserver-upgrade
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"

execute "upgrade_process" do
  command "chef-server-ctl upgrade; sleep 10; chef-server-ctl restart"
  action :nothing
end

yum_package "chef-server-core" do
  action :upgrade
  notifies :run, "execute[upgrade_process]"
end
