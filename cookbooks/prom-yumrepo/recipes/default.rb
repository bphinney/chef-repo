#
# Cookbook Name:: prom-yumrepo
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'

service 'httpd' do
  if node['platform_version'].to_i == '7'
    stop_command    '/usr/bin/systemctl stop httpd'
    start_command   '/usr/bin/systemctl start httpd'
    reload_command  '/usr/sbin/apachectl reload'
    restart_command '/usr/bin/systemctl restart httpd'
  else
    stop_command    '/etc/init.d/httpd stop'
    start_command   '/etc/init.d/httpd start'
    reload_command  '/etc/init.d/httpd graceful'
    restart_command '/etc/init.d/httpd restart'
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :enable => true, :graceful => true
  action :nothing
end

# Perform default http stuff
include_recipe 'prom-http::default'

%w{createrepo yum-utils}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

# aws components
include_recipe 'promaws::default'
aws = data_bag_item('aws-sdk', 'main')

# Add storage for yumrepo container data
unless node['yumrepo_data_volume'].nil? || node['yumrepo_data_volume'].empty?
  # Create and attach aws ebs volume
  node['yumrepo_data_volume'].each do |device, size|
    aws_ebs_volume `hostname`.strip! + '-yumrepo_data_vol' do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size size
      device device
      region node['aws_node_region'] if node['requires_aws_region']
      action [ :create, :attach ]
      only_if { node['provider'] == 'aws' }
    end
  end
end

if !node['yumrepo_data_mount'].nil?
  # Add mount for yumrepo data containment of container data
  node['yumrepo_data_mount'].each do |mount, device|
    directory mount do
      action :create
    end
    bash "Running mkfs.ext4 on device: #{device}" do
      __command  = "mkfs.ext4 #{device}"
      __fs_check = 'dumpe2fs'
      code __command
      not_if "#{__fs_check} #{device}"
    end
    mount mount do
      device device
      fstype 'ext4'
      options 'noatime'
      action [:enable, :mount]
    end
  end
end

%w{yum-repo yum-repo/prometheanrelease yum-repo/prometheancommon yum-repo/prometheanspecial}.each do |dir|
  directory "#{node['yum']['yumrepo_data']}/#{dir}" do
    action :create
    owner  'root'
    group  'root'
    recursive true
  end
end

# Ensure SELinux is disabled allow httpd access to yum-repo directory
include_recipe "prom-default::selinux"

template '/etc/httpd/conf.d/yumrepo.conf' do
  source 'yumrepo.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  action :create
  notifies :restart, 'service[httpd]'
end

template "/etc/yum.repos.d/promethean.repo" do
  source "promethean.repo.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  action :create
end

node['yum']['yumrepo_dirlink'].each do |dir|
  link "#{node['yum']['yumrepo_data']}/yum-repo/#{dir}" do
    to   "#{node['yum']['yumrepo_data']}/yum-repo/promethean#{dir}"
  end
end

template '/usr/local/bin/repo-sync' do
  source 'reposync.erb'
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
end

cron 'reposync' do
  command '/usr/local/bin/repo-sync > /var/log/reposync.log 2>&1'
  minute '0'
  hour   '*'
  action :create
end
