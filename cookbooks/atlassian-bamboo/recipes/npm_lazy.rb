#
# Cookbook Name:: atlassian-bamboo
# Recipe:: npm_lazy
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

yum_repository 'epel' do
  description 'Extra Packages for Enterprise Linux 6 - $basearch'
  mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch'
  gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
  action :create
end

%w{nodejs npm}.each do |package|
  package package do
    :upgrade
  end
end

service 'npm_lazy' do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

execute 'npm_lazy-install' do
  command 'cd /opt/bamboo-data/storage/npm_lazy; npm install'
  action :nothing
end

git '/opt/bamboo-data/storage/npm_lazy' do
  repository 'https://github.com/mixu/npm_lazy.git'
  reference  'master'
  action     :sync
  notifies :run, 'execute[npm_lazy-install]'
end

template '/etc/init.d/npm_lazy' do
  source 'npm_lazy-init.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

template '/opt/bamboo-data/.npmrc' do
  source 'npmrc.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0644'
end

service 'npm_lazy' do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable, :start]
end

cron 'npm_lazy-check' do
  command '/sbin/service npm_lazy server_check > /var/log/npm_lazy-check.log'
  minute  '*/15'
  hour    '*'
end

