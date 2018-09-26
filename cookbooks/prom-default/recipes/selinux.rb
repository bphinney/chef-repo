#
# Cookbook Name:: prom-default
# Recipe:: default
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

execute "selinux-disable" do
  if node['platform_version'] >= '7'
    command "echo 0 > /sys/fs/selinux/enforce"
  else
    command "echo 0 > /selinux/enforce"
  end
  not_if "grep 0 /selinux/enforce"
  action :nothing
end

template "/etc/sysconfig/selinux" do
  source "selinux.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  manage_symlink_source(true) if respond_to?(:manage_symlink_source)
  notifies :run, "execute[selinux-disable]", :immediately
end

