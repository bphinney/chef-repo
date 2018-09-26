#
# Cookbook Name:: prom-activfoundation
# Recipe:: logback-foundation
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

template "/opt/tomcat/conf/logback-foundation.xml" do
  source "foundation.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

