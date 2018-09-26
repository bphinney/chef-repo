#
# Cookbook Name:: prom-local
# Recipe:: elasticsearch
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Recipes for elasticsearch installation on Vagrant

# Clears the existing installation of elasticsearch on centos65 box
bash "clear_old_elasticsearch" do
  code <<-EOH
  service elasticsearch stop
  rm -f /etc/init.d/elasticsearch
  rm -rf /usr/local/bin/elasticsearch
  rm -rf /usr/local/etc/elasticsearch
  rm -rf /usr/local/elasticsearch
  rm -rf /usr/local/var/data/elasticsearch*
  rm -rf /usr/local/var/log/elasticsearch*
  rm -rf /usr/local/var/run/elasticsearch*
  rm -rf /usr/local/elasticsearch*
  EOH
  # Extra guards to prevent unintended removal
  only_if { File.exist?('/usr/local/bin/elasticsearch')}
  only_if { node['elasticsearch']['clear_old_install'] == 'true' }
end

node_name             = node.name
elasticsearch_version = node['elasticsearch']['elasticsearch_version']

# Install specific version of elasticsearch
execute "elasticsearch: #{elasticsearch_version}" do
  command "rpm -U --nodeps --force https://download.elastic.co/elasticsearch/elasticsearch/#{elasticsearch_version}.noarch.rpm"
  not_if  "rpm -qa | grep -q '#{elasticsearch_version}'"
  action  :run
end

# Elasticsearch requires executable permissions on the data directory
directory '/opt/elasticsearch' do
  owner     'root'
  group     'root'
  mode      '0755'
  recursive  true
end
%w{/etc/elasticsearch}.each do |directory|
  directory directory do
    owner     'root'
    group     'root'
    mode      '0755'
    recursive  true
  end
end

# Configure elasticsearch memory optimizations
template '/etc/sysconfig/elasticsearch' do
  source 'sysconfig-elastic.erb'
  owner  'root'
  group  'root'
  mode   '0644'
end

# Initiate elasticsearch configuration
template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(
      :node_name => node_name
    )
end

# Plugins/tools installation

# TODO: Check pip dependency
# Install elasticsearch curator plugin using pip
#execute 'curator_install' do
#  command 'pip install elasticsearch-curator'
#  action :run
#  not_if 'pip list | grep elasticsearch-curator'
#end

execute 'head' do
  command '/usr/share/elasticsearch/bin/plugin --install mobz/elasticsearch-head'
  action :run
  not_if 'test -d /usr/share/elasticsearch/plugins/head'
end

execute 'bigdesk' do
  command '/usr/share/elasticsearch/bin/plugin --install lukas-vlcek/bigdesk'
  action :run
  not_if 'test -d /usr/share/elasticsearch/plugins/bigdesk'
end

execute 'marvel' do
  command '/usr/share/elasticsearch/bin/plugin --install elasticsearch/marvel/latest'
  action :run
  not_if 'test -d /usr/share/elasticsearch/plugins/marvel'
end

template '/etc/cron.daily/log-elasticsearch' do
  source 'logrotate-elasticsearch.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

service 'elasticsearch' do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
