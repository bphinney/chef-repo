#
# Cookbook Name:: prom-elasticsearch
# Recipe:: elasticsearch-marvel
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Plugins installation
execute "head" do
  command "/usr/local/elasticsearch/bin/plugin --install mobz/elasticsearch-head"
  action :run
  not_if "test -d /usr/local/elasticsearch/plugins/head"
end

execute "bigdesk" do
  command "/usr/local/elasticsearch/bin/plugin --install lukas-vlcek/bigdesk"
  action :run
  not_if "test -d /usr/local/elasticsearch/plugins/bigdesk"
end

execute "marvel" do
  command "/usr/local/elasticsearch/bin/plugin --install elasticsearch/marvel/latest"
  action :run
  not_if "test -d /usr/local/elasticsearch/plugins/marvel"
end

template "/etc/cron.daily/log-elasticsearch" do
  source "logrotate-elasticsearch.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

# Elasticsearch Cluster Size Detection
unless node.chef_environment.include?("local")
  esNodes       = node['elasticsearch']['discovery']['zen']['ping']['unicast']['hosts']
  esArray       = esNodes.split(",")
  esClusterSize = esArray.map.size

  if esClusterSize == 2
    # Set Override attribute for discovery zen minimum_master_nodes to 1
    node.override['elasticsearch']['discovery']['zen']['minimum_master_nodes'] = 1
  end  
end
