#
# Cookbook Name:: promethean
# Recipe:: phpfpm-remove
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl reload"
    restart_command "/usr/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports :start => true, :stop => true, :status => true, :reload => true, :graceful => true
  action :nothing
end

service "php-fpm" do
  supports :start => true, :stop => true, :status => true, :reload => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

%w{php php-dom php-pdo php-gd php-mbstring php-mysql php-fpm mod_fastcgi}.each do |pkg|
  package pkg do
    action :remove
    notifies :run, "execute[configcheck]"
  end
end

template "/etc/httpd/conf.d/php.conf" do
  source "php.conf.erb"
  owner  "root"
  group  "root"
  action :delete
  notifies :run, "execute[configcheck]"
end

directory "/usr/lib/cgi-bin" do
  recursive true
end

template "/etc/httpd/conf.d/fastcgi.conf" do
  source "fastcgi.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  action :delete
  only_if { File.exists?("/etc/httpd/conf.d/fastcgi.conf") }
  notifies :run, "execute[configcheck]"
end

service "php-fpm" do
  supports :start => true, :stop => true, :status => true, :reload => true
  action [:stop,:disable]
  only_if { node['apache']['mpm'] == "worker" }
  notifies :run, "execute[configcheck]"
end
