#
# Cookbook Name:: prom-http
# Recipe:: worker
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/bin/systemctl stop httpd"
    start_command "/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl graceful"
    restart_command "/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports stop: true, start: true, restart: true, status: true, reload: true, graceful: true
  action :nothing
end

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
  only_if { node['apache']['mpm'] == "worker" }
end
