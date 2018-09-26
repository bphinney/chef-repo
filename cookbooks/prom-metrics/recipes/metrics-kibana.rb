#
# Cookbook Name:: prom-metrics
# Recipe:: metrics-kibana
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Installs base Kibana

include_recipe 'prom-metrics::metrics-server'
include_recipe 'prom-metrics::metrics-elasticsearch'

kibana_version = node['metrics_server']['kibana_version']

%w{ /www/data/kibana }.each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode  "0755"
    recursive true
    action :create
  end
end

### Kibana Installation ###

bash "kibana: install" do
  guard_interpreter :bash
  code <<-EOH
  cd /tmp
  wget https://download.elastic.co/kibana/kibana/#{kibana_version}.tar.gz
  tar xzvf #{kibana_version}.tar.gz
  rm #{kibana_version}.tar.gz
  mv /tmp/#{kibana_version}/* /www/data/kibana
  EOH
  not_if "test -f /www/data/kibana/bin/kibana"
end

# Configuration for Kibana 3
template '/www/data/kibana/config.js' do
  source 'sm-kibana-config.js.erb'
  owner  'root'
  group  'root'
  mode   '0644'
end

execute 'Kibana start' do
  command 'cd /www/data/kibana/ && bin/kibana &'
  action :run
  not_if 'pidof kibana'
end
