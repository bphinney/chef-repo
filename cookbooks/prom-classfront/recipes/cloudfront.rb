#
# Cookbook Name:: prom-classfront
# Recipe:: cloudfront
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Service call to restart,stop,start a service (httpd)
# Called from `configcheck`
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

# Configcheck called when a change is made
execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

yum_package "mod_cdn" do 
  action :install 
end

template "/etc/httpd/conf.d/cdn.conf" do
    source "cdn.conf.erb"
    owner 'root'
    group 'root'
    mode '0644'
    # if there is a change, run config check, config check also does a service restart 
    notifies :run, "execute[configcheck]" 
end

# Clean up *rpmnew and *rpmsave files if they exist
file  '/etc/httpd/conf.d/cdn.conf.rpmnew' do 
  action :delete
  only_if { File.exists?('/etc/httpd/conf.d/cdn.conf.rpmnew') }
end

file  '/etc/httpd/conf.d/cdn.conf.rpmsave' do 
  action :delete
  only_if { File.exists?('/etc/httpd/conf.d/cdn.conf.rpmsave') }
end

