#
# Cookbook Name:: prom-pmaint
# Recipe:: parent-maint
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"
include_recipe "prom-activtomcat::activtomcat"
include_recipe "prom-presearch"

parentmaint_version = node['applications']['backend']['parentmaint_version']

yum_package "parent-maint" do
  version parentmaint_version
  action :install
  not_if { parentmaint_version == '0.0.0-1' }
end

directory "/opt/tomcat/bin/pmaint" do
  recursive true
  owner "tomcat"
  group "tomcat"
end

template "/usr/local/bin/parent-maint" do
  source "parent-maint.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0755"
  not_if { Dir.glob('/opt/tomcat/bin/pmaint/parent-maint-*.jar').empty? }
end

######################
## Global Resources ##
######################
## IN-1217 Removing references to tenantdssor chef
$env             = node.chef_environment
$tenants         = search(:foundation, "env:#{$env}")
$afconf          = "activfoundation.properties.erb"
$fmconf          = "parent-maint.properties.erb"
$tenants.each do |tenant|
  if tenant["tenant_config.is_default_tenant"] == "\u0001"
      $tenant_id = tenant["tenant_config.id"]
  end
end

#################################
## End Global Resource Section ##
#################################

if node['database'].attribute?('dbserver')
  mysqlserver = node['database']['dbserver']
end

solonode = node
activnodes = []
if Chef::Config[:solo] 
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.")
  activnodes = solonode['ipaddress']
else
  unless node.environment.include?("local")
    $presearch_node['activfoundation_nodes'].each do |member|
      unless member['ipaddress'].nil?
        activnodes << member['ipaddress']
      end
    end
  else
    activnodes << "127.0.0.1"
  end
  activnodes = activnodes.collect { |worker| worker }.sort.uniq.join(",")
end

# Elasticsearch nodes
elasticnodes = []
if Chef::Config[:solo] 
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.")
  elasticnodes = solonode['ipaddress']
else
  unless node.chef_environment.include?("local") 
    $presearch_node['elasticsearch_nodes'].each do |elastic|
      elasticnodes << elastic['ipaddress']
    end
    elasticnodes = elasticnodes.collect { |worker| worker }.sort.uniq.join(",")
  else
    elasticnodes << "127.0.0.1"
    elasticnodes = elasticnodes.collect { |worker| worker }.sort.uniq.join(",")
  end
end

unless node["elasticsearch_service"].nil? || node["elasticsearch_service"].empty?
  elasticnodes = node["elasticsearch_service"]
end

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end

template "/opt/tomcat/conf/parent-maint.properties" do
  source "parent-maint.properties.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  variables(
           :mysqlserver => mysqlserver,
           :activnodes => activnodes,
           :elasticnodes => elasticnodes,
           :emailserver => mailserver["smtpserver"],
           :emailuser => mailserver["smtpuser"],
           :emailpass => mailserver["smtppass"],
           :tenants => $tenants
           )
end

include_recipe "prom-pmaint::logback-pmaint"

