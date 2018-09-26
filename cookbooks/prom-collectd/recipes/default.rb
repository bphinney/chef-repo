#
# Cookbook Name:: prom-collectd
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"
include_recipe "prom-default::selinux"
include_recipe "prom-default::hostsfile"
include_recipe "yum::default"

collectd_version = node['collectd']['version']
graphite_host    = node['collectd']['graphite_host']
metrics_active   = node['collectd']['metrics_active']
profiling_active = node['collectd']['profiling_active']

# Collectd daemon instalaltion
if node['platform_version'].to_i == "7" 
  yum_package "collectd" do
    allow_downgrade false
    if metrics_active == "true"
      action :install
    else
      action :remove
    end 
  end 
else
  yum_package "collectd.x86_64" do
    version collectd_version
    allow_downgrade true
    not_if { collectd_version == '0.0.0-1' }
    if metrics_active == "true"
      action :install
    else
      action :remove
    end 
  end 
end

service "collectd" do
  supports :stop => true, :start => true, :restart => true, :status => true
  if metrics_active == "true"
    action [ :enable, :start ]
  else
    action [ :stop ]
  end
end

template "/etc/collectd.conf" do
  source "collectd.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[collectd]"
  variables(
      :environment    => node.chef_environment,
      :graphite_host  => graphite_host
    )
  if metrics_active == "true"
    action :create
  else
    action :delete
  end
end

# Elasticsearch Metrics
# Client-side elasticsearch instance metrics for metrics-server
cookbook_file "/usr/lib/python2.6/site-packages/elasticsearch_collectd.py" do
  source "elasticsearch_collectd.py"
  owner "root"
  group "root"
  mode  "0755"
  notifies :restart, "service[collectd]"
  if profiling_active == "true" && node.recipes.include?("prom-elasticsearch")
    action :create
  else
    action :delete
  end
end

cluster_name   = node['aws_elasticsearch']['cluster_name'] 
elastic_host   = node['aws_elasticsearch']['rest_url']
elastic_port   = node['aws_elasticsearch']['port']
index_stats    = 'true'
cluster_stats  = 'true'

begin
indices = ""
index_search = JSON.parse(`curl -s #{elastic_host}/_aliases?`)
index_search.each do |index, _alias|
  if index.include?("foundation")
    indices += "\"#{index}\", "
  end
end
indices_list = indices.chomp(", ")
rescue
  indices_list = ""
end

# Aws Elasticsearch Metrics
# Server-side elasticsearch metrics intended for Aws Elasticsearch Service
template "/usr/lib/python2.6/site-packages/aws_elastic_collectd.py" do
  source "elasticsearch_collectd.py.erb"
  owner "root"
  group "root"
  mode  "0755"
  variables(
    :cluster_name   => cluster_name,
    :elastic_host   => elastic_host,
    :elastic_port   => elastic_port,
    :index_stats    => index_stats,
    :indices_list   => indices_list,
    :cluster_stats => cluster_stats
  )
  notifies :restart, "service[collectd]"
  if node['aws_elasticsearch'].attribute?('aws_elastic_metrics') && node['aws_elasticsearch']['aws_elastic_metrics'] == 'true'
    action :create
  else
    action :delete
  end
end

# Elasticache Metrics
# Server-side Metrics for Aws Elasticache Service (Redis)
template "/usr/lib/python2.6/site-packages/redis_info.py" do
  source "elasticache_collectd.py"
  owner "root"
  group "root"
  mode  "0755"
  notifies :restart, "service[collectd]"
  if node['collectd'].attribute?('elasticache_metrics') && node['collectd']['elasticache_metrics'] == 'true'
    action :create
  else
    action :delete
  end
end

