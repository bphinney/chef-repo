#
# Cookbook Name:: prom-local
# Recipe:: local_db_setup
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Include necessary recipes
include_recipe "prom-default"

service "mysql" do
  supports :start => true, :stop => true, :restart => true
  action :nothing
end

# Recipe specific variables
if node.chef_environment.include?("local")
  $db_user      = "root"
  $db_pass      = "root"
  $db_setup     = "/usr/bin/db-setup"
  $db_secret    = "/root/.mysql_secret"
else
  exit
  # Exit this recipe if not local, safeguard for other envs. 
end

# For centos 7, remove mariadb libraries to prevent conflict with mysql
if node['platform_version'].to_i == '7' 
  yum_package "mariadb-libs" do
    action :remove
  end 
end

# Install or update Mysql Server, Client and Shared Compat libraries
%w(MySQL-shared-compat MySQL-server MySQL-client).each do |pkg|
  yum_package pkg do
    action :upgrade
  end
end
service "mysql" do
  action [:enable,:start]
end

# Add template for my.cnf
template "/etc/my.cnf" do
  source "my.cnf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[mysql]"
end

## Initial DB Super User Password change
ruby_block "root-database-setup" do
  block do
    %x(pass=`grep random #{$db_secret} |tail -1|cut -d':' -f4 | cut -d' ' -f2` && mysqladmin -u#{$db_user} -p$pass password #{$db_pass} &>/dev/null && #{$db_setup})
    #%x(pass=`grep random #{$db_secret} |tail -1|cut -d':' -f4 | cut -d' ' -f2` && mysql -p$pass -e "SET PASSWORD FOR '#{$db_user}'@'localhost' = PASSWORD('#{$db_pass}');" 2>/dev/null && #{$db_setup})
  end
  action :run
  only_if { File.exists?($db_secret) and File.exists?($db_setup) and !Dir.glob('/opt/tomcat/bin/maint/foundation-maint-*.jar').empty? } 
end
