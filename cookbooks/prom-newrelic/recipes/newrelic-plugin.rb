#
# Cookbook Name:: prom-newrelic
# Recipe:: newrelic-plugin
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "newrelic"
include_recipe "python::pip"

service "newrelic-plugin-agent" do
  supports :stop => true, :start => true, :restart => true, :status => true, :reload => true
  action :nothing
end

# Install plugin using pip
execute "plugin_install" do
  command "pip install newrelic-plugin-agent"
  action :run
  not_if "pip list | grep newrelic-plugin-agent"
end

#Create newrelic log and run directories
%w{/var/run/newrelic /var/log/newrelic}.each do |dir|
  directory dir do
    owner "newrelic"
    group "newrelic"
  end
end

#Create newrelic config directory
directory "/etc/newrelic" do
  action :create
end

# Configuration file for newrelic plugin agent
template "/etc/newrelic/newrelic-plugin-agent.cfg" do
  source "newrelic-plugin-agent.cfg.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

# Create the init.d/systemd script
if node['platform_version'].to_i == '7'
  cookbook_file '/usr/lib/systemd/system/newrelic-plugin-agent.service' do
    source 'newrelic-plugin-agent.service'
    owner 'root'
    group 'root'
    mode '0755'
  end
end

execute "newrelic_plugin_init" do
  command "cp /opt/newrelic-plugin-agent/newrelic-plugin-agent.rhel /etc/init.d/newrelic-plugin-agent; chmod +x /etc/init.d/newrelic-plugin-agent"
  action :run
  not_if { File.exists?("/etc/init.d/newrelic-plugin-agent") }
end

# Enable the plugin service
service "newrelic-plugin-agent" do
  supports :stop => true, :start => true, :restart => true, :status => true, :reload => true
  action [:enable,:start]
end
