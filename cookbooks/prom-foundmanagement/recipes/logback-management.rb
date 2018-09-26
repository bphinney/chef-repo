#
# Cookbook Name:: prom-foundmanagement
# Recipe:: logback-management
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

template '/opt/tomcat/conf/logback-management.xml' do
  source 'management.logback.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end

