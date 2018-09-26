#
# Cookbook Name:: atlassian-bamboo
# Recipe:: build
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

execute 'yum-update' do
  command 'yum update'
  action :nothing
end

%w{rpm-build gcc libgcc.i686 make java-1.7.0-openjdk java-1.7.0-openjdk-devel java-1.8.0-openjdk java-1.8.0-openjdk-devel}.each do |package|
  package package do
    :upgrade
  end
end

%w{nodejs npm}.each do |package|
  yum_package package do
    action :remove
  end
end

execute 'nodejs-version' do
  command "npm install -g n;n #{node['nodejs_version']}"
  action :run
end

execute 'npm-version' do
  command "cd /usr/local/lib/node_modules/;node npm install npm@#{node['npmjs_version']}"
  action :run
end

execute 'ant-install' do
  command "cd /usr/lib; unzip /opt/apache-ant-#{node['maven']['ant_version']}-bin.zip; rm -f /usr/bin/ant"
  action :nothing
end

remote_file "/opt/apache-ant-#{node['maven']['ant_version']}-bin.zip" do
  source "http://apache.mirrors.pair.com/ant/binaries/apache-ant-#{node['maven']['ant_version']}-bin.zip"
  action :nothing
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, 'execute[ant-install]'
end

http_request "http://apache.mirrors.pair.com/ant/binaries/apache-ant-#{node['maven']['ant_version']}-bin.zip" do
  url "http://apache.mirrors.pair.com/ant/binaries/apache-ant-#{node['maven']['ant_version']}-bin.zip"
  message ''
  action :head
  if File.exists?("/opt/apache-ant-#{node['maven']['ant_version']}-bin.zip")
    headers "If-Modified-Since" => File.mtime("/opt/apache-ant-#{node['maven']['ant_version']}-bin.zip").httpdate
  end
  notifies :create, "remote_file[/opt/apache-ant-#{node['maven']['ant_version']}-bin.zip]", :immediately
end

link '/usr/bin/ant' do
  to "/usr/lib/apache-ant-#{node['maven']['ant_version']}/bin/ant"
  action :create
end

execute 'maven-install' do
  command "cd /usr/lib; unzip /opt/apache-maven-#{node['maven']['version']}-bin.zip; rm -f /usr/bin/mvn"
  action :nothing
end

remote_file "/opt/apache-maven-#{node['maven']['version']}-bin.zip" do
  source "http://apache.mirrors.pair.com/maven/binaries/apache-maven-#{node['maven']['version']}-bin.zip"
  action :nothing
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :run, 'execute[maven-install]'
end

http_request "http://apache.mirrors.pair.com/maven/binaries/apache-maven-#{node['maven']['version']}-bin.zip" do
  url "http://apache.mirrors.pair.com/maven/binaries/apache-maven-#{node['maven']['version']}-bin.zip"
  message ''
  action :head
  if File.exists?("/opt/apache-maven-#{node['maven']['version']}-bin.zip")
    headers "If-Modified-Since" => File.mtime("/opt/apache-maven-#{node['maven']['version']}-bin.zip").httpdate
  end
  notifies :create, "remote_file[/opt/apache-maven-#{node['maven']['version']}-bin.zip]", :immediately
end

link '/usr/bin/mvn' do
  to "/usr/lib/apache-maven-#{node['maven']['version']}/bin/mvn"
  action :create
end

template "/usr/lib/apache-maven-#{node['maven']['version']}/conf/settings.xml" do
  source 'settings.xml.erb'
  owner  'root'
  group  'root'
  mode   '0644'
end

# Install the prerequisites for building git from source.
%w{perl-ExtUtils-MakeMaker gettext-devel expat-devel curl-devel zlib-devel openssl-devel openssl-devel gcc-c++ make}.each do |app|
  package app do
    :upgrade
  end
end
# Create the directory we will install git into
directory '/opt/bamboo-data/executable/git' do
end

#Set the version, then define the build command
git_version = '1.9.0'
execute 'git-install' do
  command "cd /opt/bamboo-data/storage; tar -xzvf /opt/bamboo-data/storage/git-#{git_version}.tar.gz; cd /opt/bamboo-data/storage/git-#{git_version}; ./configure; ./make; make prefix=/opt/bamboo-data/executable/git install"
  action :nothing
end

# This is the remote file that we will pull to build from
remote_file "/opt/bamboo-data/storage/git-#{git_version}.tar.gz" do
  source "https://git-core.googlecode.com/files/git-#{git_version}.tar.gz"
  action :create_if_missing
  owner  'bamboo'
  group  'bamboo'
  mode   '0644'
  notifies :run, 'execute[git-install]'
end

# Databag look up of appnames and write to node attribute
app_names = data_bag_item('activfoundation', 'applications')
appnames = ''
app_names['names'].each do |name,version|
  appnames = appnames + "#{name}|#{version} "
end
#Chef::Log.info('appnames string will be #{appnames}')
template '/opt/bamboo-data/executable/rpm-package' do
  source 'rpm-package.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
  variables(:appnames => appnames)
end

template '/opt/bamboo-data/executable/dev-deployment' do
  source 'dev-deployment.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
end

template '/opt/bamboo-data/executable/nagioscommand' do
  source 'nagioscommand.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
end

#include_recipe 'atlassian-bamboo::npm_lazy'

template '/opt/bamboo-data/executable/ui-build' do
  source 'ui-build.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
end

#section for Python used by webclipper build
package 'bamboopython' do
  action :upgrade
end

link '/opt/bamboo-data/executable/python/bin/python' do
  to '/opt/bamboo-data/executable/python/bin/python2.7'
  only_if 'test -f /opt/bamboo-data/executable/python/bin/python2.7'
end

link '/usr/bin/npm' do
  to '/usr/local/bin/npm'
  only_if 'test -f /usr/local/bin/npm'
end

link '/usr/bin/node' do
  to '/usr/local/bin/node'
  only_if 'test -f /usr/local/bin/node'
end

link '/usr/lib/node_modules' do
  to '/usr/local/lib/node_modules'
  only_if 'test -d /usr/local/lib/node_modules'
end

nagios_host = []
if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef solo does not support search.')
else
  search(:node, 'role:monitoring' ).each do |worker|
    hostsfile_entry worker['ipaddress'] do
      hostname worker['hostname']
      action :create
      unique true
      comment 'Updated by Chef'
    end
  end
end

