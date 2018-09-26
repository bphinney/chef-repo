#
# Cookbook Name:: prom-foundasync
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
template "/opt/tomcat/conf/logback-async.xml" do
  source "async.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

