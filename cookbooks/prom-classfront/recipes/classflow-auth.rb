#
# Cookbook Name:: prom-classfront
# Recipe:: classflow-auth
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/bin/systemctl stop httpd"
    start_command "/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl graceful"
    restart_command "/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports stop: true, start: true, restart: true, status: true, reload: true, graceful: true
  action :nothing
end

# Action to run to check for configuration errors
# Also does a service call to restart `httpd`
execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

# Perform default mod_security actions
include_recipe "prom-http::mod_security"

template "/usr/local/bin/oauth_response" do
  source "oauth_response.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(
    :souschefloc => "#{node['souschef_location']}" == '' ? 'chef-server' : "#{node['souschef_location']}"
  )
  only_if { "#{node["provider"]}" == "aws" }
end

template "/usr/local/bin/googleoauth_response" do
  source "googleoauth_response.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(
    :souschefloc => "#{node['souschef_location']}" == '' ? 'chef-server' : "#{node['souschef_location']}"
  )
  only_if { "#{node["provider"]}" == "aws" }
end

template "/usr/local/bin/of365oauth_response" do
  source "of365oauth_response.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(
    :souschefloc => "#{node['souschef_location']}" == '' ? 'chef-server' : "#{node['souschef_location']}"
  )
  only_if { "#{node["provider"]}" == "aws" }
end

cron "oauth-response" do
  command "/usr/local/bin/oauth_response > /var/log/oauth_response 2>&1"
  hour    "*"
  minute  "0"
  action :create
  only_if { "#{node["provider"]}" == "aws" }
end

cron "googleoauth-response" do
  command "/usr/local/bin/googleoauth_response > /var/log/googleoauth_response 2>&1"
  hour    "*"
  minute  "0"
  action :create
  only_if { "#{node["provider"]}" == "aws" }
end

cron "of365oauth-response" do
  command "/usr/local/bin/of365oauth_response > /var/log/of365oauth_response 2>&1"
  hour    "*"
  minute  "0"
  action :create
  only_if { "#{node["provider"]}" == "aws" }
end

