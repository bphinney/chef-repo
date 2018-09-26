#
# Cookbook Name:: prom-http
# Recipe:: mod_security
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl reload"
    restart_command "/usr/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

%w{mod_security}.each do |pkg|
  package pkg do
    action :upgrade
    notifies :run, "execute[configcheck]"
  end
end

secruleeng = "#{node['apache']['secruleengine']}" == '' ? 'On' : "#{node['apache']['secruleengine']}"

package "mod_security_crs" do
  action :remove
  only_if { secruleeng == 'On' }
end

cookbook_file "/etc/httpd/modsecurity.d/modsecurity_crs_10_custom.conf" do
  source "modsecurity_crs_10_custom.conf"
  owner  "root"
  group  "root"
  mode   "0644"
  only_if { secruleeng == 'On' }
  notifies :run, "execute[configcheck]"
end

package "mod_security_crs" do
  action :upgrade
  notifies :run, "execute[configcheck]"
  not_if { secruleeng == 'On' }
end

template "/etc/httpd/conf.d/mod_security.load" do
  source "mod_security.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(
    :secruleengine => secruleeng
  )
  notifies :run, "execute[configcheck]"
end

%w{mod_security php-fcgid}.each do |mod|
  file "/etc/httpd/conf.d/#{mod}.conf" do
    action :delete
    only_if "test -f /etc/httpd/conf.d/#{mod}.conf"
  end
end


