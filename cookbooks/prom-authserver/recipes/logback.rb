
# Cookbook Name:: prom-authserver
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

template '/opt/tomcat/conf/logback-auth.xml' do
  source 'authserver-log.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end
