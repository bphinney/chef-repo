#
# Cookbook Name:: prom-local
# Recipe:: mysql
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

service "mysql" do
  supports :start => true, :stop => true, :restart => true
  action :nothing
end


%w{MySQL-server MySQL-client MySQL-shared-compat}.each do |package|
  yum_package package do
    action :upgrade
  end
end

template "/etc/my.cnf" do
  source "my.cnf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[mysql]"
end
