#
# Cookbook Name:: prom-foundetlapp
# Recipe:: logback-etl-app
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

template "/opt/tomcat/conf/logback-etl-app.xml" do
  source "logback-etl-app.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

