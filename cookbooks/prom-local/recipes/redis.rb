# 
# Cookbook Name:: promethean
# Recipe:: redis
#
# Copyright 2015, Promethean
#
# All Rights Reserved - Do Not Redistribute
#

include_recipe "prom-default"

if node.chef_environment.include?("local")

  service "redis" do 
    supports :start => true, :stop => true, :restart => true
    action :nothing
  end

  package "redis" do
    action :upgrade
  end

  # Adding these entries as a desired level, but on local, probably don't need them  
  execute "sysctl_reload" do
    command "sysctl -p"
    returns [0,255]
    action :nothing
  end

  entries = ['vm.overcommit_memory=1','fs.file-max=100000','net.core.somaxconn=65535']
  entries.each do |entry|
    append_if_no_line entry do
      path "/etc/sysctl.conf"
      line entry
      notifies :run, "execute[sysctl_reload]"
    end
  end

  directory "/opt/redis/data" do
    recursive true
    action :create
    owner "redis"
    group "redis"
  end
 
  template "/etc/redis.conf" do
    source "redis.conf.erb"
    action :create
    notifies :restart, "service[redis]"
  end

  service "redis" do
    supports :start => true, :stop => true, :restart => true
    action [:start,:enable]
  end  
end
