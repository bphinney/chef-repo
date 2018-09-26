#
# Cookbook Name:: prom-metrics
# Recipe:: metrics-elasticsearch
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Recipes for elasticsearch installation on metrics-server

include_recipe "prom-metrics::metrics-server"

elasticsearch_version = node['metrics_server']['elasticsearch_version']

# Install specific version of elasticsearch
execute "elasticsearch: #{elasticsearch_version}" do
   command "rpm -U --nodeps --force https://download.elastic.co/elasticsearch/elasticsearch/#{elasticsearch_version}.noarch.rpm"
  not_if "rpm -qa | grep -q '#{elasticsearch_version}'"
  action :run
end

# Install elasticsearch curator plugin using pip
execute "curator_install" do
  command "pip install elasticsearch-curator"
  action :run
  not_if "pip list | grep elasticsearch-curator"
end

# Configure elasticsearch memory optimizations
# Currently runs as single node on metrics server
template "/etc/sysconfig/elasticsearch" do
  source "sm-sysconfig-es.erb"
  owner  'root'
  group  'root'
  mode   "0644"
end

# Initiate elasticsearch configuration
template "/etc/elasticsearch/elasticsearch.yml" do
  source "sm-elasticsearch.yml.erb"
  owner  'root'
  group  'root'
  mode   "0644"
  variables(
      :node_name => node_name
    )
end

service "elasticsearch" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

# Cron cleanup and backup operations
template '/etc/cron.daily/prune_es_indices' do
  source 'sm-prune_indices.erb'
  owner  'root'
  group  'root'
  mode   '0755'
  variables(
      :elastic    => true,
      :ip_address => node['ipaddress']
    )
end
