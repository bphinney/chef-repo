#
# Cookbook Name:: android_ota
# Recipe:: proftpd
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Include necessary recipes

# Instance URL
host_url  = node['android_ota']['host_url']
# mysql Access
db_host   = node['android_ota']['db_hostname']
mysql     = data_bag_item("mysql", "mysqlserver") # Lookup forroot defaults
db_user   = mysql['mysqladminuser']
db_pass   = mysql['mysqladminpass']
# ota4user database
sftp_db   = node['android_ota']['sftp_dbname']
sftp_user = node['android_ota']['sftp_dbuser']
sftp_pass = node['android_ota']['sftp_dbpass']
# proftpd settings
sftp_root = node['android_ota']['sftp_root']
sftp_port = node['android_ota']['sftp_port']

proftpd_version = '1.3.3g-8.el6'

service "proftpd" do
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true
  action :nothing
end

# Install necessary rpm dependencies for ProFTPD Administrator
# Version shared by all packages
%w{proftpd proftpd-mysql proftpd-utils}.each do |pkg|
  yum_package pkg do
    proftpd_version
    action :install
  end
end

# Setup Proftpd Main Configuration
include_recipe 'onddo_proftpd::default'
# On-The-Fly replacement of proftpd conf pointer to sftp config
s = resources(template: '/etc/proftpd/proftpd.conf')
s.cookbook('android_ota')
s.source('proftpd.conf.erb')

# Setup Proftpd SFTP Module configuration
template '/etc/proftpd/conf.d/ota_sftp.conf' do
  source 'sftp.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(
    :host_url  => host_url,
    :db_host   => db_host,
    :sftp_db   => sftp_db,
    :sftp_user => sftp_user,
    :sftp_pass => sftp_pass,
    :sftp_root => sftp_root,
    :sftp_port => sftp_port
  )
  notifies :restart, 'service[proftpd]'
end

#### Create mysql database schema for proftpd ####

mysql_connect = "mysql -u #{db_user} -p#{db_pass} -h #{db_host}"
schema_exists = `#{mysql_connect} -e "show databases like '#{sftp_db}';"`.include?("#{sftp_db}")

execute 'create_schema' do
  command  "#{mysql_connect} -N -B -e \"create database if not exists #{sftp_db};\""
  action :nothing
  notifies :run, 'execute[create_proftpd_admin_user]'
end

execute 'create_proftpd_admin_user' do
  command "#{mysql_connect} -N -B -e \"create user '#{sftp_user}'@'%' identified by '#{sftp_pass}';\""
  action :nothing
  notifies :run, 'execute[grant_proftpd_admin_privileges]'
end

execute 'grant_proftpd_admin_privileges' do
  command "#{mysql_connect} -N -B -e \"grant all privileges on #{sftp_db}.* to #{sftp_user}@'%';\""
  action :nothing
  notifies :run, 'execute[populate_proftpd_admin_table]'
end

# Tables.sql sourced from proftpd_admin repository
execute 'populate_proftpd_admin_table' do
  command "#{mysql_connect} -D #{sftp_db} < /etc/proftpd/tables.sql"
  action :nothing
end

# Two-factor schema protection
# Only creates proftpd_admin schema if
# - tables.sql is not set
# - Schema does not already exist
cookbook_file "/etc/proftpd/tables.sql" do
  source 'tables.sql'
  owner 'root'
  group 'root'
  mode  '0600'
  notifies :run, "execute[create_schema]"
  not_if { schema_exists }
end

#### END Create mysql database schema for android_ota ####

# NOTE: Placeholder - TEMPORARY TEST KEY
# TODO: Remove test pubkey when complete
cookbook_file '/etc/proftpd/authorized_keys' do
  source 'authorized_keys'
  owner  'root'
  group  'root'
  mode   '0644'
end
