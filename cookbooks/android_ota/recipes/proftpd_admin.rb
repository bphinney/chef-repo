#
# Cookbook Name:: android_ota
# Recipe:: proftpd_admin
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# PHP-based Administrative interface for Proftpd
#

host_url  = node['android_ota']['host_url']
db_host   = node['android_ota']['db_hostname']
# proftpd database
sftp_db   = node['android_ota']['sftp_dbname']
sftp_user = node['android_ota']['sftp_dbuser']
sftp_pass = node['android_ota']['sftp_dbpass']
# sftp settings
sftp_root = node['android_ota']['sftp_root']
sftp_port = node['android_ota']['sftp_port']

proftpd_admin_version = '2.1b'

# Version based on repository tag
remote_file "/tmp/proftp_admin_#{proftpd_admin_version}.zip" do
  source "https://yumrepo.prometheanjira.com/core/proftpd_admin_v#{proftpd_admin_version}.zip"
  # Original remote source
  #source "https://github.com/ChristianBeer/ProFTPd-Admin/archive/v#{proftpd_admin_version}.zip"
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
  not_if "test -f /tmp/proftp_admin_#{proftpd_admin_version}.zip"
end

execute 'unzip proftpd_admin' do
  command "unzip /tmp/proftp_admin_#{proftpd_admin_version}.zip -d /opt/"
  not_if "test -d /opt/ProFTPd-Admin-#{proftpd_admin_version}"
end

directory "/opt/ProFTPd-Admin-#{proftpd_admin_version}/configs" do
  owner  'nginx'
  group  'nginx'
  mode   '0755'  # required
  action :create
end

template "/opt/ProFTPd-Admin-#{proftpd_admin_version}/configs/config.php" do
  source 'proftpd_admin_config.php.erb'
  owner  'nginx'
  group  'nginx'
  mode   '0755'  # required
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

# Set webserver ownership of proftpd admin files
execute 'chown nginx' do
  command "chown -R nginx:nginx /opt/ProFTPd-Admin-#{proftpd_admin_version}/"
  action :run
end

directory '/opt/proftpd_admin' do
  owner  'nginx'
  group  'nginx'
  mode   '0755'
  action :create
end
 
# Clean up primary proftpd_admin directory path
link '/opt/proftpd_admin/admin' do
  to "/opt/ProFTPd-Admin-#{proftpd_admin_version}"
  link_type :symbolic
end
