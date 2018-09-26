#
# Cookbook Name:: promethean
# Recipe:: screenservice
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"

service "screenservice" do
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

%w{nodejs screenservice}.each do |package|
  package package do
    action :upgrade
    notifies :restart, "service[screenservice]"
  end
end

if node['platform_version'].to_i == '7'
  template "/usr/local/bin/screenservice" do
    source "screenservice-init.erb"
    owner "tomcat"
    group "tomcat"
    mode "0755"
  end
  cookbook_file "/usr/lib/systemd/system/screenservice.service" do
    source "screenservice.service"
    owner "root"
    group "root"
    mode "0755"
  end
else
  template "/opt/screenservice/bin/screenservice" do
    source "screenservice-init.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0755"
  end
end

cron "screen-check" do
  if node['platform_version'].to_i == '7'
    command "/usr/local/bin/screenservice autocheck > /var/log/screencheck.log 2>&1"
  else
    command "/sbin/service screenservice autocheck > /var/log/screencheck.log 2>&1"
  end
  minute  "*/10"
  hour    "*"
  action :delete
end
