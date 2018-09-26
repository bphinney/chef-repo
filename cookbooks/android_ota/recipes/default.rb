#
# Cookbook Name:: android_ota
# Recipe:: default
#
# Copyright 2016, Promethean, Inc
#
# All rights reserved - Do Not Redistribute
#
# Initial installations for ota updater 
#

include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-default::selinux' # For mysql 
include_recipe 'prom-default::hostsfile'

host_url   = node['android_ota']['host_url']
db_service = node['android_ota']['db_service']
elb_name   = node['android_ota']['sftp_elbname']
htpasswd   = node['android_ota']['htpasswd_password']

# Applications
nginx_version = '1.8.1-1.el6.ngx'  # From http://nginx.org
php_version   = '5.3.3-46.el6_7.1' # From http://www.php.net/releases/
mysql_version = '5.5'              # From mysql cookbook repository

# Lookup for standard mysql root defaults
mysql = data_bag_item('mysql', 'mysqlserver')
db_password = mysql['mysqladminpass']

# Configures nginx repository for latest version
yum_repository 'nginx' do
  description 'Nginx repository'
  baseurl 'http://nginx.org/packages/centos/$releasever/$basearch/'
  gpgcheck false
  action :create
end

yum_package 'nginx' do
  version nginx_version
  action :install
end

# Install php and ancillaries
# All packages share the same version
%w{ php-fpm php-common php-mysql }.each do |package|
  yum_package package do
    action :install
    version php_version
  end
end

service 'nginx' do
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true
  action :nothing
end

service 'php-fpm' do
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true
  action :nothing
end

# Initialize mysql database
# mysql service utilizes custom service name (i.e. - service mysql-foo status)
mysql_service db_service do
  port '3306'
  version mysql_version
  initial_root_password db_password
  provider Chef::Provider::MysqlService::Sysvinit # CentOS 6
  action [:create, :start]
end

# Ensure tcp socket is utilized for mysql
mysql_config 'configure_tcp_socket' do
  source 'mysql_tcp.erb'
  notifies :restart, "mysql_service[#{db_service}]"
  action :create
end

# Primary nginx configuration template
template '/etc/nginx/conf.d/default.conf' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  variables(
    :host_url => host_url
  )
  notifies :restart, 'service[nginx]'
  notifies :restart, 'service[php-fpm]'
end

# Generates secure authentication for htpasswd file
# Password is salted, so hash will change on each chef-client run
secure_pass = `(PASSWORD="#{htpasswd}";SALT="$(openssl rand -base64 3)";SHA1=$(printf "$PASSWORD$SALT" | openssl dgst -binary -sha1 | xxd -ps | sed 's#$#'"\`echo -n $SALT | xxd -ps\`"'#' | xxd -r -ps | base64);printf "{SSHA}$SHA1")`

# Secure web root with a password
template '/etc/nginx/conf.d/.htpasswd' do
  source 'proftpd_htpasswd.erb'
  owner 'nginx'
  group 'nginx'
  mode  '0755'
  sensitive true
  variables(
    :secure_pass => secure_pass
  )
  notifies :reload, 'service[nginx]'
end

# TODO - Add additional log-rotations
template '/etc/logrotate.d/nginx' do
  source 'logrotate-nginx.erb'
  owner  'root'
  group  'root'
  mode   '0644'
end

# Default Nginx content directory
directory '/var/www' do
  owner 'nginx'
  group 'nginx'
  mode  '0755'
  recursive true
end

# Empty default content file
template '/var/www/index.html' do
  source 'index_empty.html.erb'
  owner 'nginx'
  group 'nginx'
  mode  '0644'
end

# Install Proftpd sftp server
include_recipe 'android_ota::proftpd'

# Install Proftpd Admin Interface
include_recipe 'android_ota::proftpd_admin'

# Install Zidoo ota4user admin panel
include_recipe 'android_ota::ota4user'


#### Aws components ####

include_recipe "promaws::default"

include_recipe "android_ota::ota-elb"

# Create /etc/hosts entry
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  hostsfile_entry node['ipaddress'] do
    hostname node['hostname']
    action :create; unique true
  end
end

# Add storage for android sftp container data
include_recipe "android_ota::ota-vol"

include_recipe "android_ota::ota-snap"
