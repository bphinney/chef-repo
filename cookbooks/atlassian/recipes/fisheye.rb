#
# Cookbook Name:: atlassian
# Recipe:: fisheye
#
# Copyright 2012, Altisource
#
# All rights reserved - Do Not Redistribute
#

include_recipe "atlassian::hostsfile"

package "httpd" do
  action :upgrade
end

template "/etc/init.d/fisheye" do
  source "fisheye-init.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

service "fisheye" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

service "httpd" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

remote_file "/opt/fisheye/lib/dbdrivers/mysql/mysql-connector-java-5.1.30.jar" do
  source "http://yumrepo.prometheanjira.com/core/mysql-connector-java-5.1.30.jar"
  mode  "0644"
  owner "root"
  group "root"
  action :create_if_missing
end

file "/opt/fisheye/lib/dbdrivers/mysql/mysql-connector-java-5.1.26.jar" do
  action :delete
  only_if "test -f /opt/fisheye/lib/dbdrivers/mysql/mysql-connector-java-5.1.30.jar"
  notifies :restart, "service[fisheye]"
end

execute "cfg-xml-backup" do
  command 'mv /opt/fisheye-data/config.xml.bak /opt/fisheye-data/config.xml.bak-`date +%s`; cp -a /opt/fisheye-data/config.xml /opt/fisheye-data/config.xml.bak'
  only_if '[[ `diff -qN /opt/fisheye-data/config.xml /opt/fisheye-data/config.xml.bak` ]]'
  action :run
end

template "/opt/fisheye-data/config.xml" do
  source "fisheye.cfg.xml.erb"
  owner  "fisheye"
  group  "fisheye"
  mode   "0644"
  not_if "test -f /opt/fisheye-data/config.xml"
  notifies :restart, "service[fisheye]"
end

template "/etc/httpd/conf.d/crucible.conf" do
  source "httpd_rewrite.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:appname => "crucible", 
            :sslRedirect => "true"
           )
  notifies :restart, "service[httpd]"
end

cron "fisheyelog_cleanup" do
  minute "0"
  hour   "0"
  day    "*"
  month  "*"
  weekday "*"
  user   "root"
  command "find /opt/fisheye-data/var/log -name *.log -mtime +5 -exec rm -f {} \;"
  action :create
end

service "fisheye" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable,:start]
end

