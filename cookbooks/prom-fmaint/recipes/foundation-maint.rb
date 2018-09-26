#
# Cookbook Name:: prom-fmaint
# Recipe:: foundation-maint
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"
include_recipe "prom-activtomcat::activtomcat"
include_recipe "prom-presearch"

foundationmaint_version = node['applications']['backend']['foundationmaint_version']

yum_package "foundation-maint" do
  version foundationmaint_version
  action :install
  not_if { foundationmaint_version == '0.0.0-1' }
end

directory "/opt/tomcat/bin/maint" do
  recursive true
  owner "tomcat"
  group "tomcat"
end

template "/usr/local/bin/foundation-maint" do
  source "foundation-maint.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0755"
  not_if { Dir.glob('/opt/tomcat/bin/maint/foundation-maint-*.jar').empty? }
end

######################
## Global Resources ##
######################
$env             = node.chef_environment
$tenants         = search(:foundation, "env:#{$env}")
$afconf          = "activfoundation.properties.erb"
$fmconf          = "foundation-maint.properties.erb"
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

template "/opt/tomcat/conf/foundation-maint.properties" do
  source "foundation-maint.properties.erb"
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

include_recipe "prom-fmaint::logback-maint"

