#
# Cookbook Name:: prom-logback
# Recipe:: logging-backend
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

if File.exists?("/opt/tomcat/conf/logback-foundation.xml")
  include_recipe "prom-activfoundation::logback-foundation"
end

if File.exists?("/opt/tomcat/conf/logback-async.xml")
  include_recipe "prom-foundasync::logback"
end

if File.exists?("/opt/tomcat/conf/logback-load.xml")
  include_recipe "prom-foundload::logback"
end

if File.exists?("/opt/tomcat/conf/logback-maint.xml")
  include_recipe "prom-fmaint::logback-maint"
end

if File.exists?("/opt/vertx/conf/logback-collab.xml")
  include_recipe "prom-collabserver::logback-collab"
end

if File.exists?("/opt/tomcat/conf/logback-etl-app.xml")
  include_recipe "prom-foundetl::logback-etl-app"
end

if File.exists?('/opt/tomcat/conf/logback-global-service.xml')
  include_recipe "prom-globalservice::logback"
end

if File.exists?('/opt/tomcat/conf/logback-notification-service.xml')
  include_recipe "prom-globalservice::logback"
end

if File.exists?('/opt/tomcat/conf/logback-store-service.xml')
  include_recipe "prom-globalservice::logback"
end

if File.exists?('/opt/tomcat/conf/logback-parent-service.xml')
  include_recipe "prom-parentservice::logback"
end

if File.exists?('/opt/tomcat/conf/logback-flipchart-integration.xml')
  include_recipe "prom-flipchart::logback"
end

if File.exists?('/opt/vertx/conf/logback-collab.xml')
  include_recipe "prom-collabserver::logback"
end

if File.exists?('/opt/tomcat/conf/logback-auth.xml')
  include_recipe "prom-authserver::logback"
end
