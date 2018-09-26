#
# Cookbook Name:: prom-sftp
# Recipe:: sftp-server
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Include necessary recipes
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "prom-default::selinux"
include_recipe "prom-default::hostsfile"

# Install necessary rpm dependencies for ProFTPD Administrator
%w{MySQL MySQL-shared-compat proftpd proftpd-mysql proftpd-utils php php-mysql}.each do |pkg|
  yum_package pkg do; action :upgrade; end  # Upgrades pkg
end

# Attributes in the data_bag sftp
begin
  proftpd = data_bag_item("sftp", "proftpd")
rescue Net::HTTPServerException
  Chef::Log.info("No proftpd configuration attribues found in the data bag.")
end 

# Remove the proftpd_admin package
package "proftpd_admin" do
  action :remove
end

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

# Setup Proftpd Main Configuration - on-the-fly replacement
include_recipe 'onddo_proftpd::default'
  s = resources(template: '/etc/proftpd/proftpd.conf')
  s.cookbook('prom-sftp')
  s.source('proftpd.conf.erb')

# Setup Proftpd SFTP Module configuration
template "/etc/proftpd/conf.d/kuno_sftp.conf" do
  source "kuno_sftp.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
    variables(
      :apacheservername => proftpd['apacheservername'],
      :dbserverhostname => proftpd['dbserverhostname'],
      :databasename     => proftpd['databasename'],
      :databaseuser     => proftpd['databaseuser'],
      :databasepass     => proftpd['databasepass'],
      :sftpopenport     => proftpd['sftpopenport']
    )
end

# Setup Proftpd Admin Main Configuration XML.  This was moved 
# from the default location to /var/lib/misc
template "/var/lib/misc/configuration.xml" do
  source "proftpdadm_config.xml.erb"
  owner "apache"
  group "apache"
  mode  "0400"
    variables(
      :apacheservername => proftpd['apacheservername'],
      :dbserverhostname => proftpd['dbserverhostname'],
      :databasename     => proftpd['databasename'],
      :databaseuser     => proftpd['databaseuser'],
      :databasepass     => proftpd['databasepass'],
      :sftpopenport     => proftpd['sftpopenport'],
      :ftproot          => proftpd['ftproot']
    )
end

# Make sure the Proftpd Admin web root is secure
#template "/opt/proftpd_admin_v1.2/.htpasswd" do
#  source "proftpd_htpasswd.erb"
#  owner "apache"
#  group "apache"
#  mode  "0600"
#end

# Change ownership
#execute "chown apache" do
#  command "chown -R apache:apache /opt/proftpd_admin_v1.2"
#  action :run
#end

# Symlink required for the ftpwho utility
link "/usr/local/bin/ftpwho" do
  to "/usr/bin/ftpwho"
  link_type :symbolic
  action :create
end

# Symlink required for the who command
link "/bin/who" do
  to "/usr/bin/who"
  link_type :symbolic
  action :create
end

# aws components
include_recipe "prom-sftp::sftp-server-elb"

include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")

# Apache service for ProFTPD Administrator frontend - We are no longer maintaining this per Todd Giacometti - 11/4/2015 
service "httpd" do 
  action [:disable, :stop] 
end

service "proftpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/bin/systemctl stop proftpd"
    start_command "/bin/systemctl start proftpd"
    reload_command "/bin/systemctl reload proftpd"
    restart_command "/bin/systemctl restart proftpd"
  end
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true
  action :nothing
end

# Create /etc/hosts entry for SFTP-SERVER
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  hostsfile_entry node['ipaddress'] do
    hostname node['hostname']
    action :create; unique true
  end
end

# Add storage for sftp container data 
include_recipe "prom-sftp::sftp-server-vol"

# Install aws snapshot backups
include_recipe "prom-sftp::sftp-server-snap"

# Attributes in the data_bag sftp
begin
  foundationdbags = search(:sftp, "foundationroot:*")
rescue Net::HTTPServerException
  Chef::Log.info("No foundationroot configuration attribues found in the sftp data bag.")
end

template "/etc/proftpd/conf.d/foundation_sftp.conf" do
  source "foundation_sftp.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[proftpd]"
  variables(
    :foundationbags => foundationdbags
  )
end

foundationdbags.each do |foundbag|
  # Enforce minimum default xferelbname 
  unless foundbag['foundationelb'].nil? || foundbag['foundationelb'].empty?
    node.default['xferelbname'] = foundbag['foundationelb'] 
  end

  # Connect to the Foundation Xfer ELB
  aws_elastic_lb "#{node['xferelbname']}" do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    name node['xferelbname']
    action :register
    region node['aws_node_region'] if node['requires_aws_region']
    only_if { node['provider'] == 'aws' }
  end

  # Create containment folder per bag configuration
  directory "#{foundbag['foundationroot']}" do
    owner "root"
    group "root"
    mode  "0777"
    action :create
  end
  
  file "#{foundbag['foundationcurrent']}" do
    owner "root"
    group "root"
    mode  "0644"
    action :create
    not_if "test -f #{foundbag['foundationcurrent']}"
  end

  file "#{foundbag['foundationauthfile']}" do
    owner "root"
    group "root"
    mode  "0640"
    action :create
    not_if "test -f #{foundbag['foundationauthfile']}"
  end

  file "#{foundbag['foundationauthgroup']}" do
    owner "root"
    group "root"
    mode  "0640"
    action :create
    not_if "test -f #{foundbag['foundationauthgroup']}"
  end

  execute "foundation-xferadmin-#{foundbag.id}" do
    command "echo #{foundbag['foundationpass']} | /usr/bin/ftpasswd --passwd --file=#{foundbag['foundationauthfile']} --name=#{foundbag['foundationadmin']} --uid=#{foundbag['foundationuid']} --gid=#{foundbag['foundationgid']} --home=#{foundbag['foundationroot']} --shell=/bin/true --stdin"
    sensitive true
    action :run
    only_if "test -f #{foundbag['foundationauthfile']}"
  end

  execute "foundation-xfergroup-#{foundbag.id}" do
    command "/usr/bin/ftpasswd --group --name=foundation --gid=#{foundbag['foundationgid']} --member=#{foundbag['foundationadmin']} --file=#{foundbag['foundationauthgroup']}"
    sensitive true
    action :run
    only_if "test -f #{foundbag['foundationauthgroup']}"
  end
end

# Include the sftp-tenant recipe which creates credentials for tenants
#include_recipe "prom-sftp::sftp-tenant"
