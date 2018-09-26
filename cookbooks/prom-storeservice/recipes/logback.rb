# Cookbook Name:: prom-storeservice
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

# globalservice logback file
template '/opt/tomcat/conf/logback-store-service.xml' do
  source 'logback-store-service.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end
