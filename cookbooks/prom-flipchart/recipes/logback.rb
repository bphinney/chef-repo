#
# Cookbook Name:: prom-flipchart
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
template '/opt/tomcat/conf/logback-flipchart-integration.xml' do
  source 'flipchart.logback.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end
