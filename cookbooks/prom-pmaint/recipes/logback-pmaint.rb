#
# Cookbook Name:: prom-fmaint
# Recipe:: logback-maint
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

template "/opt/tomcat/conf/logback-parent-maint.xml" do
  source "pmaint.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

template "/opt/tomcat/conf/logback-pmaint-tool.xml" do
  source "pmainttool.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

