#
# Cookbook Name:: prom-foundload
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

template "/opt/tomcat/conf/logback-load.xml" do
  source "load.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

