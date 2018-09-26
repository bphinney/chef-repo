#
# Cookbook Name:: prworld
# Recipe:: supportmegasite
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl graceful"
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

#############################################
## Start of support mega site installation ##
#############################################

directory "/opt/www/supportmegasite" do
  recursive true
end

template "/etc/httpd/conf.d/supportmegasite.conf" do
  source "supportmegasite.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  if node['supportmega']['supportmega_install'] == "false"
    action :delete
  elsif node['supportmega']['supportmega_install'] == "true"
    action :create
  end
  notifies :run, "execute[configcheck]"
  variables( :countryblock => node['countryblock'].split(",")
  )
end
