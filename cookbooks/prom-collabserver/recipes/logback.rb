#
# Cookbook Name:: prom-collabserver
# Recipe:: logback
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

template '/opt/vertx/conf/logback-collab.xml' do
  source 'collabserver.logback.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end

