#
# Cookbook Name:: promethean
# Recipe:: stagemonitor 
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

unless node.chef_environment.include?("local")
  # Access AWS Credentials
  aws = data_bag_item("aws-sdk", "main")
  include_recipe "aws::default"
  # Create and attach volume for whisper
  aws_ebs_volume `hostname`.strip! + "-whisper_vol" do
    aws_access_key aws['aws_access_key_id']
    aws_secret_access_key aws['aws_secret_access_key']
    size 80
    device "/dev/sdg"
    action [ :create, :attach ]
  end
end

# Necessary package gcc for twisted
package "gcc" do
  action :install
  not_if "rpm -q gcc"
end

# Install necessary packages
# Note - Removed supervisor and git. Add back if necessary
%w{wget curl graphite-web python-carbon}.each do |pkg|
  yum_package pkg do
    action :install
  end
end

%w{/www/data/grafana /www/data/kibana}.each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
end

directory "/var/lib/carbon" do
  owner 'carbon'
  group 'carbon'
  action :create
end

mountpoints = []
mount = "/var/lib/carbon"
device = "/dev/xvdk"
directory mount do
  action :create
end
bash "Format device: #{device}" do
    __command = "mkfs.ext4 #{device}"
    __fs_check = 'dumpe2fs'

    code __command

    not_if "#{__fs_check} #{device}"
end
mount mount do
  device device
  fstype "ext4"
  options "noatime"
  action [:enable, :mount]
end
mountpoints << mount

# Elasticsearch 
execute "elasticsearch: version-1.3.4" do
  command "rpm -U --nodeps --force https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.4.noarch.rpm"
not_if "rpm -qa | grep -q 'elasticsearch-1.3.4'"
  action :nothing
end.run_action(:run)

# Install elasticsearch curator plugin using pip
execute "curator_install" do
  command "pip install elasticsearch-curator"
  action :run
  not_if "pip list | grep elasticsearch-curator"
end

# Grafana 1.9 Installation
bash "grafana: install" do
  guard_interpreter :bash
  code "cd /tmp && wget http://grafanarel.s3.amazonaws.com/grafana-1.9.1.tar.gz && tar xzvf grafana-1.9.1.tar.gz && rm grafana-1.9.1.tar.gz && mv /tmp/grafana-1.9.1/* /www/data/grafana"
  not_if "test -f /www/data/grafana/index.html"
end

# Grafana 2.0 Installation
bash "grafana: install" do
  guard_interpreter :bash
  code "cd /tmp && wget https://grafanarel.s3.amazonaws.com/builds/grafana-2.0.1.linux-x64.tar.gz && tar xzvf grafana-2.0.1.linux-x64.tar.gz && rm grafana-2.0.1.linux-x64.tar.gz && mv /tmp/grafana-2.0.1/* /www/data/grafana20"
  not_if "test -f /www/data/grafana20/bin/grafana-server"
end

# Kibana Instalaltion
bash "kibana: install" do
  guard_interpreter :bash
  code "cd /tmp && wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.1.tar.gz && tar xzvf kibana-3.1.1.tar.gz && rm kibana-3.1.1.tar.gz && mv /tmp/kibana-3.1.1/* /www/data/kibana"
  not_if "test -f /www/data/kibana/index.html"
end

# Let's enable apache 
service "httpd" do
  action [:enable, :start]
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :reload, "service[httpd]"
end

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

$host_url = "http://stagemonitor.prometheanjira.com"
#$node_name = "cf-stagemonitor1"
$node_name = node['node_name']

# Configuration for Grafana 1.9
template "/www/data/grafana/config.js" do
  source "sm-grafana-config.js.erb"
  owner 'root'
  group 'root'
  mode "0644"
  variables(
      :host_url => $host_url
    ) 
end

# Configruration for Grafana 2.0
template "/www/data/grafana20/conf/custom.ini" do
  source "sm-grafana-custom.ini.erb"
  owner 'root'
  group 'root'
  mode "0644"
  variables(
      :host_url => $host_url,
      :node_name => $node_name
    ) 
end

# Configuration for Kibana 3
template "/www/data/kibana/config.js" do
  source "sm-kibana-config.js.erb"
  owner 'root'
  group 'root'
  mode "0644"
end

# Configure elasticsearch memory optimizations
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

# Let's enable the carbon-cache service
service "carbon-cache" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end

# Let's enable elasticsearch service
service "elasticsearch" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
end

# Let's make sure the sqlite3 graphite database is created
execute "graphite-admin: database" do
  command "/usr/lib/python2.6/site-packages/graphite/manage.py syncdb --noinput"
  action :run
end

# Initiate Grafana 2.0
execute "Grafana20 start" do
  command "cd /www/data/grafana20/ && bin/grafana-server web &"
  action :run
  not_if "pidof grafana-server"
end

# Connect to the Stagemonitor ELB in AWS-EC2
if node["provider"] == "aws"
  unless node['sm_elb'].nil? || node['sm_elb'].empty?
    node.default['elbname'] = node['sm_elb']
    return unless (node['aws']['instance_id'] rescue false)
    aws_elastic_lb "#{node['elbname']}" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      name node['elbname']
      action :register
    end
  end
end

template "/etc/cron.daily/prune_indices" do
  source "sm-prune_indices.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  variables(
      :ip_address => node['ipaddress']
    )
end 

# TODO - Add grafana 2.0 restart operation.
