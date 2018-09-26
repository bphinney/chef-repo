#
# Cookbook Name:: prom-fmaint
# Recipe:: logback-maint
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

template "/opt/tomcat/conf/logback-maint.xml" do
  source "maint.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

template "/opt/tomcat/conf/logback-tool.xml" do
  source "mainttool.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

