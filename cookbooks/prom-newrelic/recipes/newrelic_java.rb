#
# Cookbook Name:: promethean
# Recipe:: newrelic_java
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

file "/opt/newrelic/newrelic.jar" do
  action :delete
  only_if { node['newrelic']['upgrade'] == "force" }
end

newrelic_agent_java 'Install' do
  license node['newrelic']['application_monitoring']['license']  
  install_dir node['newrelic']['java_agent']['install_dir']
  app_user node['newrelic']['java_agent']['app_user']
  app_group node['newrelic']['java_agent']['app_group']
  agent_type 'java'
  app_name node['newrelic']['application_monitoring']['app_name']
  execute_agent_action false
  error_collector_ignore_errors node['newrelic']['application_monitoring']['error_collector']['ignore_errors']
  error_collector_ignore_status_codes node['newrelic']['application_monitoring']['error_collector']['ignore_status_codes']
end

