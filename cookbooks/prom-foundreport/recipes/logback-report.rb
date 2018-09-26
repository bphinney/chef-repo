#
# Cookbook Name:: prom-foundreport
# Recipe:: logback-report
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

template '/opt/tomcat/conf/logback-report.xml' do
  source 'report.logback.xml.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
end

