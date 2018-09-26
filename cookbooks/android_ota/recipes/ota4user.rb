#
# Cookbook Name:: android_ota
# Recipe:: ota4user
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Installation and configuration of Zidoo ota4user application
# for Android OTA Updates

# Nginx server name
host_url  = node['android_ota']['host_url']
# Mysql access
db_host   = node['android_ota']['db_hostname']
mysql     = data_bag_item("mysql", "mysqlserver") # Lookup forroot defaults
db_user   = mysql['mysqladminuser']
db_pass   = mysql['mysqladminpass']
# ota4user database
ota_db    = node['android_ota']['ota4user_dbname']
ota_user  = node['android_ota']['ota4user_dbuser']
ota_pass  = node['android_ota']['ota4user_dbpass']

# Extract and place ota4user contents
remote_file '/tmp/ota4user.tar.gz' do
  source 'https://yumrepo.prometheanjira.com/core/ota4user.tar.gz'
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
  not_if "test -f /tmp/ota4user.tar.gz"
end

execute 'unzip ota4user' do
  command "tar -xf /tmp/ota4user.tar.gz -C /opt/"
  not_if "test -d /opt/ota4user"
end

# Set webserver ownership of ota4user files
execute 'chown nginx ota4user' do
  command "chown -R nginx:nginx /opt/ota4user/"
  action :run
end

execute 'set ota4user write permissions' do
  command "chmod -R 755 /opt/ota4user/"
end

#### Create mysql database schema for ota4user ####
mysql_connect = "mysql -u #{db_user} -p#{db_pass} -h #{db_host}"
schema_exists = `#{mysql_connect} -e "show databases like '#{ota_db}';"`.include?("#{ota_db}")

execute 'create_ota4user_schema' do
  command "#{mysql_connect} -N -B -e \"create database if not exists #{ota_db};\""
  action :nothing
  notifies :run, "execute[create_ota4user_user]"
end

execute 'create_ota4user_user' do
  command "#{mysql_connect} -N -B -e \"create user '#{ota_user}'@'%' identified by '#{ota_pass}';\""
  action :nothing
  notifies :run, "execute[grant_ota4user_privileges]"
end

execute 'grant_ota4user_privileges' do
  command "#{mysql_connect} -N -B -e \"grant all privileges on #{ota_db}.* to #{ota_user}@'%';\""
  action :nothing
  notifies :run, "execute[populate_ota4user_table]"
end

# ota4user.sql sourced from ota4user package
execute 'populate_ota4user_table' do
  command "#{mysql_connect} -D #{ota_db} < /opt/ota4user.sql"
  action :nothing
end

# Two-factor schema protection
# Only creates ota4user schema if
# - ota4user.sql is not set
# - Schema does not already exist
cookbook_file '/opt/ota4user.sql' do
  source 'ota4user.sql'
  owner 'root'
  group 'root'
  mode  '0600'
  notifies :run, "execute[create_ota4user_schema]"
  not_if { schema_exists }
end

template '/opt/ota4user/Runtime/Conf/config.php' do
  source 'ota4user_config.php.erb'
  owner  'nginx'
  group  'nginx'
  mode   '0755'  # required
  variables(
    :ota_db    => ota_db,
    :ota_user  => ota_user,
    :ota_pass  => ota_pass,
    :db_host   => db_host
  )
end

#### Workarounds and customizations for ota4user application ####

# Removes cache file in the package that conflicts/overrides config.php
file '/opt/ota4user/Runtime/~app.php' do
  action :delete
end

# If more than one base version is set for a device (such as disabled or dev devices, 
# the app will only select the first one, even if disabled. This file was provided by 
# Zidoo to patch the issue.
cookbook_file '/opt/ota4user/Lib/Lib/Action/Home/RomAction.class.php' do
  source 'RomAction.class.php'
  owner 'nginx'
  group 'nginx'
  mode '0755'
  action :create
end

# Removes sql file in the package root directory
file '/opt/ota4user/ota4user.sql' do
  action :delete
end

# ota4user requires a writable Runtime Cache directory
# for user management
directory '/opt/ota4user/Runtime/Cache/Admin/' do
  owner  'nginx'
  group  'nginx'
  recursive true
  mode   '0777'  # required
end

# ota4user requires a customized writable saved sessions directory
# (configured in ota-fpm.conf, below)
directory '/tmp/php_sessions' do
  owner  'nginx'
  group  'nginx'
  recursive true
  mode   '0777'  # required
end

# php-fpm overrides php.ini with the following settings
# This is the default file with required values for ota4user
template '/etc/php-fpm.d/www.conf' do
  source 'www.conf.erb'
  owner  'nginx'
  group  'nginx'
  mode   '0755'  # required
  notifies :restart, 'service[php-fpm]'
end


