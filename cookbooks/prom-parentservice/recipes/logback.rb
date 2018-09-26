# Cookbook Name:: prom-parentservice
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

template '/opt/tomcat/conf/logback-parent-service.xml' do
  source 'logback-parent-service.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end

