#
# Cookbook Name:: beaver
# Recipe:: default
#
# Copyright 2014, promethean/rsavage 
#
include_recipe 'python'

python_pip 'beaver' do 
  version node['beaver']['version']
  action :install
end

python_pip 'argparse' do
  action :install
end

directory node['beaver']['config_path'] do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

directory ::File.join(node['beaver']['config_path'], "conf.d") do
  owner 'root'
  group 'root'
  mode 0755
  action :create
end

if node['beaver']['generate_keypair']
  include_recipe 'beaver::generate_keypair'
end

service 'beaver' do
  supports :start => true, :restart => true, :stop => true, :status => true
  action :nothing
end

template "#{node['beaver']['config_path']}/#{node['beaver']['config_file']}" do
  source 'beaver.conf.erb'
  owner 'root'
  group 'root'
  mode 00644
  variables(
    :beaver => node['beaver']['configuration'],
    :files => node['beaver']['files']
  )
  notifies :restart, "service[beaver]"
end

template "/etc/init.d/beaver" do
  source "beaver-init.erb"
  owner 'root'
  group 'root'
  mode 0755
  variables(
    :config_path => node['beaver']['config_path'],
    :config_file => node['beaver']['config_file'],
    :log_path => node['beaver']['log_path'],
    :log_file => node['beaver']['log_file']
  )
end

service 'beaver' do
  action [:enable, :start]
end
