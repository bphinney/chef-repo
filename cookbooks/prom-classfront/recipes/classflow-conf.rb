#
# Cookbook Name:: prom-classfront
# Recipe:: classflow
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

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

###<-Begin Multi-Tenant Configuration
$env                 = node.chef_environment
$env_tenant_name     = "tenants" + "#{$env}"
## IN-1217 Remove references to chef as SOR
$tenants_unsorted  = search(:foundation, "env:#{$env}")
$cftemplate        = "classflow.conf.erb"
$tenants           = $tenants_unsorted.sort_by { |k, v| k[:id] }


template "/etc/httpd/conf.d/classflow.conf" do
  source "#{$cftemplate}"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(
      :countryblock => node['countryblock'].split(","),
      :tenants => $tenants
  )
  notifies :run, "execute[configcheck]"
end

