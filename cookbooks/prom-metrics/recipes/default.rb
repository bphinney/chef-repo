#
# Cookbook Name:: promethean
# Recipe:: metrics-server 
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Include necessary recipes
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "prom-default::selinux"
include_recipe "prom-default::hostsfile"
include_recipe "yum::default"
include_recipe "java::openjdk"
include_recipe "python"
include_recipe "python::pip"
include_recipe "prom-collectd"

# Host/node definitions
$host_url = "metrics.prometheanjira.com"
$node_name = node.name

# Application Versions
elasticsearch_version = "elasticsearch-1.7.2"
grafana_one_version = "grafana-1.9.1"
grafana_two_version = "grafana-2.1.3"
kibana_version = "kibana-4.1.2-linux-x64"

# Create and attach volume for whisper
unless node.chef_environment.include?("local")
  # Access AWS Credentials
  aws = data_bag_item("aws-sdk", "main")
  include_recipe "aws::default"
  aws_ebs_volume `hostname`.strip! + "-whisper_vol" do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    size 80
    device "/dev/sdg"
    region node['aws_node_region'] if node['requires_aws_region']
    action [ :create, :attach ]
  end
end


### Directories ###

%w{/www/data/grafana /www/data/grafana10 /www/data/kibana}.each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode  "0755"
    recursive true
    action :create
  end
end


#### Graphite/Carbon ####

directory "/var/lib/carbon" do
  owner "carbon"
  group "carbon"
  action :create
end

# Necessary package for twisted for graphite
package "gcc" do
  action :install
  not_if "rpm -q gcc"
end

%w{wget curl graphite-web python-carbon}.each do |pkg|
  yum_package pkg do
    action :install
  end
end

# Graphite Configuration
template "/etc/httpd/conf.d/graphite-web.conf" do
  source "sm-graphite-web.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
end

template "/etc/graphite-web/local_settings.py" do
  source "sm-local_settings.py.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

template "/etc/carbon/carbon.conf" do
  source "sm-carbon.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

# Configure Carbon Drive Mount
#mountpoints = []
mount = "/opt"
device = "/dev/xvde"

#directory mount do
#  action :create
#end

#bash "Format device: #{device}" do
#    __command = "mkfs.ext4 #{device}"
#    __fs_check = 'dumpe2fs'
#    code __command
#    not_if "#{__fs_check} #{device}"
#end

mount mount do
  device device
  fstype "ext4"
  options "noatime"
  action [:enable, :mount]
end
#mountpoints << mount


### Elasticsearch Components ###

execute "elasticsearch: version-1.3.4" do
   command "rpm -U --nodeps --force https://download.elastic.co/elasticsearch/elasticsearch/#{elasticsearch_version}.noarch.rpm"
  not_if "rpm -qa | grep -q '#{elasticsearch_version}'"
  action :nothing
end.run_action(:run)

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
      :node_name => $node_name
    ) 
end


### Grafana 1.x Installation ###
# Grafana 1.x is utilized as Stagemonitor staging for 2.x templates

# Grafana 1.x Installation
bash "grafana: install" do
  guard_interpreter :bash
  code <<-EOH
  cd /tmp
  wget http://grafanarel.s3.amazonaws.com/#{grafana_one_version}.tar.gz
  tar xzvf #{grafana_one_version}.tar.gz
  rm #{grafana_one_version}.tar.gz
  mv /tmp/#{grafana_one_version}/* /www/data/grafana10
  EOH
  not_if "test -f /www/data/grafana10/index.html"
end

# Configuration for Grafana 1.9
template "/www/data/grafana10/config.js" do
  source "sm-grafana-config.js.erb"
  owner 'root'
  group 'root'
  mode "0644"
  variables(
      :host_url => $host_url
    ) 
end


### Grafana 2.x Installation ###

bash "grafana: install" do
  guard_interpreter :bash
  code <<-EOH
  cd /tmp
  wget https://grafanarel.s3.amazonaws.com/builds/#{grafana_two_version}.linux-x64.tar.gz
  tar xzvf #{grafana_two_version}.linux-x64.tar.gz
  rm #{grafana_two_version}.linux-x64.tar.gz
  mv /tmp/#{grafana_two_version}/* /www/data/grafana
  EOH
  not_if "test -f /www/data/grafana/bin/grafana-server"
end

# Configruration for Grafana 2.x
template "/www/data/grafana/conf/custom.ini" do
  source "sm-grafana-custom.ini.erb"
  owner 'root'
  group 'root'
  mode "0644"
  variables(
      :host_url => $host_url,
      :node_name => $node_name
    ) 
end

# Make sure the sqlite3 grafana database is created
execute "graphite-admin: database" do
  command "/usr/lib/python2.6/site-packages/graphite/manage.py syncdb --noinput"
  action :run
  not_if "test -f /www/data/grafana/grafana.db"
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
template "/www/data/kibana/config.js" do
  source "sm-kibana-config.js.erb"
  owner 'root'
  group 'root'
  mode "0644"
end


### Services ###

service "carbon-cache" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end

# Initiate Grafana 2.x
# TODO - Add grafana 2.x service
execute "Grafana start" do
  command "cd /www/data/grafana/ && bin/grafana-server web &"
  action :run
  not_if "pidof grafana-server"
end

service "elasticsearch" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end

execute "Kibana start" do
  command "cd /www/data/kibana/ && bin/kibana &"
  action :run
  not_if "pidof kibana"
end

service "httpd" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start ]
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :restart, "service[httpd]"
end


### Final Configuration ###

# Cron cleanup and backup operations
template "/etc/cron.daily/prune_indices" do
  source "sm-prune_indices.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(
      :ip_address => node['ipaddress']
    )
end 

# Connect to the metrics ELB in AWS-EC2
if node["provider"] == "aws"
  return unless (node['aws']['instance_id'] rescue false)
  aws_elastic_lb "#{node['metrics_server']['elb_name']}" do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    name node['elbname']
    region node['aws_node_region'] if node['requires_aws_region']
    action :register
  end
end
