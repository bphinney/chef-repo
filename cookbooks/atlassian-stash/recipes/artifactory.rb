#
# Cookbook Name:: atlassian-stash
# Recipe:: artifactory
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "atlassian::hostsfile"
include_recipe "java::openjdk"

service "artifactory" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

%w{/opt/jfrog/artifactory /opt/jfrog/var/opt/jfrog/artifactory}.each do |dir|
  directory dir do
    action :create
    recursive true
  end
end

link "/var/opt/jfrog" do
  to "/opt/jfrog/var/opt/jfrog"
end

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/etc/httpd/conf.d/artifactory.conf" do
  source "httpd_rewrite.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:appname => "artifactory",
            :sslRedirect => "true"
           )
  notifies :restart, "service[httpd]"
end

package "jfrog-artifactory-oss" do
  action :upgrade
  notifies :restart, "service[artifactory]"
end

package "httpd" do
  action :upgrade
end
 
template "/opt/jfrog/var/opt/jfrog/artifactory/etc/storage.properties" do
  source "storage.properties.erb"
  owner  "artifactory"
  group  "artifactory"
  mode   "0644"
  notifies :restart, "service[artifactory]"
end

service "artifactory" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable,:start]
end

