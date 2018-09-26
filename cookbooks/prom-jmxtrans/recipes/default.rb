#
# Cookbook Name:: prom-jmxtrans
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Include necessary recipes
include_recipe "java::openjdk"
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "yum::default"

service "jmx-trans" do
  supports :start => true, :stop => true, :reload => true, :restart => true
  action :nothing
end

# Install necessary Yum Packages
%w{jmxtrans}.each do |pkg|
  yum_package pkg do
    action :upgrade
  end
end

# Find ip address of the environment metrics server for the node
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  search(:node, "recipes:prom-metrics\\:\\:metrics-server AND chef_environment:#{node.chef_environment}").each do |smnode|
    $smserverip = smnode['ipaddress']
  end
end

#Pull Tools Repo
jmxtrans_version = node['applications']['tools']['jmxtrans_version']

package "jmxtrans" do
  version jmxtrans_version
  action :install
  allow_downgrade true
  not_if { jmxtrans_version == '0.0.0-1' }
end

directory '/opt/jmxtrans' do
  owner   'tomcat'
  group   'tomcat'
  recursive true
end

template '/opt/jmxtrans/jmxtrans.json' do
  source 'jmxtrans.json.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0644'
  variables(
           :smserverip => node['smserverip']
           )
end

if node['platform_version'].to_i == '7'
  template '/usr/lib/systemd/system/jmx-trans.service' do
    source 'jmxtrans.init-cent7.erb'
    owner 'tomcat'
    group 'tomcat'
    mode  '0755'
  end
else
  template '/etc/init.d/jmx-trans' do
    source 'jmxtrans.init.erb'
    owner  'tomcat'
    group  'tomcat'
    mode   '0755'
  end
end

# The script that initates jmx parameters
template '/opt/jmxtrans/jmxtrans.sh' do 
  source 'jmxtrans.sh.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0755'
  notifies :restart, "service[jmx-trans]"
end

# Conf file that allows for jmx parameter customization
template '/opt/jmxtrans/jmxtrans.conf' do 
  source 'jmxtrans.conf.erb'
  owner  'tomcat'
  group  'tomcat'
  mode   '0755'
  notifies :restart, "service[jmx-trans]"
end

# Jmxtrans service is dependent on the setting for the jmx console port (8090)
service 'jmx-trans' do
  if node['java'].attribute?('jmx_console_enable')
    if node['java']['jmx_console_enable'] == 'true'
      action [:enable, :start]
    else
      action [:disable]
    end
  end
end
