#
# Cookbook Name:: prom-http
# Recipe:: geoip
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

%w{mod_geoip GeoIP GeoIP-devel GeoIP-data zlib-devel}.each do |package|
  package package do
    action :upgrade
  end
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

template "/opt/www/static/countrytest.php" do
  source "countrytest.php.erb"
  owner  "apache"
  group  "apache"
  mode   "0644"
  action :delete
  only_if { File.exists?("/opt/www/static/countrytest.php") }
end
