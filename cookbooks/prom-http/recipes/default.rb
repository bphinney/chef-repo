#
# Cookbook Name:: prom-http
# Recipe:: default
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#


# Install `httpd`
package "httpd" do
  action :upgrade
end

# Install `mod_ldap`
package "mod_ldap" do
  action :upgrade
  only_if { node['platform_version'].to_i == '7' }
end

include_recipe "prom-http::geoip"

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/etc/logrotate.d/httpd" do
  source "logrotate-http.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

# For CentOS 7
if node['platform_version'].to_i == '7'
  cookbook_file "/etc/httpd/conf.modules.d/00-mpm.conf" do
    source "mpm-conf"
    owner "root"
    group "root"
    mode "0644"
  end
end

# Mailx package for sending messages
yum_package "mailx" do
  action :install
end

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

template "/etc/httpd/conf/httpd.conf" do
  source 'httpd.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, "execute[configcheck]"
end

#Creates default .htaccess file
include_recipe "prom-http::default_htaccess"

template "/usr/local/bin/httpd-logclean" do
  source "httpd.logclean.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

directory '/var/www/error' do
  recursive true
  owner 'apache'
  group 'apache'
  action :create
end

cookbook_file "/var/www/error/HTTP_FORBIDDEN.html.var" do
  source "HTTP_FORBIDDEN.html.var"
  owner  "root"
  group  "root"
  mode   "0644"
end

cron "httpd-logclean" do
  command "/usr/local/bin/httpd-logclean > /var/log/httpd-logclean.log 2>&1"
  minute  "20"
  hour    "4"
  action :create
end

%w{welcome.conf README}.each do |file|
  file "/etc/httpd/conf.d/#{file}" do
    action :delete
    only_if "test -f /etc/httpd/conf.d/#{file}"
    notifies :run, "execute[configcheck]"
  end
end

template "/var/www/html/.digest_pw" do
  source "digest_pw.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  if node['apache']['security'] == 'true'
    action :create
  else
    action :delete
    only_if { File.exist?("/var/www/html/.digest_pw") }
  end
end

service "httpd" do
  supports :stop => true, :start => true, :restart => true, :status => true, :enable => true
  action [:start, :enable]
end

