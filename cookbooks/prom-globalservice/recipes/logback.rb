# Cookbook Name:: prom-globalservice
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

# globalservice logback file
template '/opt/tomcat/conf/logback-global-service.xml' do
  source 'logback-global-service.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end
