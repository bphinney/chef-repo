#
# Cookbook Name:: promethean
# Recipe:: styles
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"

# Include default http stuff
include_recipe "prom-http::default"

service "httpd" do
  if node['platform_version'].to_i == "7"
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl graceful"
    restart_command "/usr/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :reload => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

directory "/opt/storage" do
  recursive true
end

directory "/opt/www/styles" do
  recursive true
  action :create
end

template "/etc/httpd/conf.d/styles.conf" do
  source "styles.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
  variables(:security => node['security'],
            :sslRedirect => node['apache']['sslRedirect']
           )
end
