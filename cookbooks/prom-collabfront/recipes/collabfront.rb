#
# Cookbook Name:: promethean
# Recipe:: collabfront
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "prom-default::selinux"
include_recipe "haproxy::default"
include_recipe "prom-collabfront::collab_sysctl"
include_recipe "prom-presearch"

#Newrelic Plugin
if node['newrelic']["newrelic-plugin-install"] == "true"
  include_recipe "prom-newrelic::newrelic-plugin"
end

service "haproxy" do
  supports :status => true, :start => true, :stop => true, :reload => true, :restart => true
  action :nothing
end

service "rsyslog" do
  supports :status => true, :start => true, :stop => true, :reload => true, :restart => true
  action :nothing
end
###############################################################################
##                      Backend Split if Necessary                           ##                
websocket_hosts = []
solonode = node
if Chef::Config[:solo] || node.environment.include?("local")
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
  websocket_hosts << solonode
else
  # Since we are not in a local environment, let's search for collab only nodes
  $presearch_node['collabserver_nodes'].each do |worker|
    websocket_hosts << worker
  end
  if websocket_hosts.empty? 
    $presearch_node['activfoundation_nodes'].each do |worker|
      websocket_hosts << worker
    end
  end
end
###############################################################################
frontend_hosts = []
if Chef::Config[:solo] || node.environment.include?("local")
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
  frontend_hosts << solonode 
else
  $presearch_node['frontend_nodes'].each do |worker|
    frontend_hosts << worker
  end
end

###<-Begin Multi-Tenant Configuration
$env                 = node.chef_environment
$env_tenant_name     = "tenants" + "#{$env}"
## Commenting out the SOR pieces as we have no environments using chef - IN-1217
$tenants_unsorted  = search(:foundation, "env:#{$env}")
$tenants           = $tenants_unsorted.sort_by { |k, v| k[:id] }

unless Chef::Config[:solo] || node.environment.include?("local")
  websocket_hosts.uniq! { |a| a.ipaddress }
  websocket_hosts.sort! { |a,b| a.ipaddress <=> b.ipaddress }
  frontend_hosts.uniq! { |a| a.ipaddress }
  frontend_hosts.sort! { |a,b| a.ipaddress <=> b.ipaddress }
end
# This counts the number of workers and calculates max connections
ws_worker = 0
websocket_hosts.each do |worker|
  ws_worker += 1
end
ws_conns = ws_worker 
# Template for haproxy configuration
template "/etc/haproxy/haproxy.cfg" do
  source "collab_proxy.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(
           :websocket_hosts => websocket_hosts,
           :ws_conns => ws_conns,
           :frontend_hosts => frontend_hosts,
           :tenants => $tenants,
           :rewrite => "#{node['collab']["haproxy_rewrite"]}" == '' ? 'false' : "#{node['collab']["haproxy_rewrite"]}"
           )
  notifies :restart, "service[haproxy]"
  not_if { websocket_hosts.nil? || websocket_hosts.empty? }
end

template "/etc/rsyslog.d/haproxy.conf" do
  source "collab_log.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[rsyslog]"
end

template "/etc/logrotate.d/haproxy" do
  source "logrotate-haproxy.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

cron "clear_haproxy_logs" do
  command "/bin/find /var/log/haproxy* -type f -mmin +8640 | /usr/bin/xargs -I {} /bin/rm {}"
  minute  "1"
  hour    "1"
end

file "/etc/rsyslog.d/30-haproxy.conf" do
  action :delete
  only_if "test -f /etc/rsyslog.d/30-haproxy.conf"
end

file "/etc/default/rsyslog" do
  action  :delete
  only_if "test -f /etc/default/rsyslog"
end

if node["provider"] == "aws"
  include_recipe "prom-collabfront::collabfront-elb"
end
