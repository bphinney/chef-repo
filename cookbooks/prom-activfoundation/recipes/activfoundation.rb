#########################################
# Cookbook Name:: prom-activfoundation
# Recipe:: activfoundation
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#########################################
include_recipe "prom-default::repo"
include_recipe "prom-activtomcat::activtomcat"
include_recipe "prom-presearch"

# Create local hosts file entry for our own IP address
include_recipe "prom-default::hostsfile"

# Mailx package for sending messages
yum_package "mailx" do
  action :install
end

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.force_default['newrelic']['application_monitoring']['app_name'] = "activfoundation"
end

include_recipe "promaws::default"

unless node.chef_environment.include?("local")
  include_recipe "glusterfs::glusterfs-af"
end

activfoun_version = node['applications']['backend']['activfoun_version']

yum_package "activfoundation" do
  version activfoun_version
  action :install
  not_if { activfoun_version == '0.0.0-1' }
  notifies :restart, "service[activtomcat]"
end

directory "/opt/tomcat/content" do
  owner "tomcat"
  group "tomcat"
end

if node['af']['content_fallback'] == "true"
  directory "/opt/tomcat/contentback" do
    owner  "tomcat"
    group  "tomcat"
  end
end

#nfsserver = []
#if (Chef::Config[:solo] || node.chef_environment.include?("local"))
#  Chef::Log.warn("Excluding NFS-SERVER hostsfile entry in local/solo mode")
#else
#  $presearch_node['nfs_primaries'].each do |server|
#    unless server['ipaddress'].nil?
#      nfsserver << server['ipaddress']
#    end
#  end
#  nfsserver=nfsserver.first 
  #$presearch_node['nfs_servers'].each do |server|
  #  hostsfile_entry server['ipaddress'] do
  #    hostname server['hostname']
  #    action :create
  #    unique true
  #  end
  #end
#end

if node.recipes.include?('glusterfs::glusterfs-af')
  contentenv = "/#{node.chef_environment}/content"
  importenv = "/#{node.chef_environment}/import"
else
  contentenv = ""
  importenv = "/import"
end

execute "change-permissions" do
  command "chown tomcat:tomcat /opt/tomcat/content; chown tomcat:tomcat /opt/tomcat/content/import"
  action :nothing
end

directory "/opt/tomcat/content" do
  recursive true
  owner "tomcat"
  group "tomcat"
  notifies :run, "execute[change-permissions]"
end

directory "/opt/tomcat/content/import" do
  recursive true
  owner "tomcat"
  group "tomcat"
  notifies :run, "execute[change-permissions]"
end

######################
## Global Resources ##
######################
$env     = node.chef_environment
$tenants = search(:foundation, "env:#{$env}")
$afconf  = "activfoundation.properties.erb"
$tenants.each do |tenant|
  if tenant["tenant_config.is_default_tenant"] == "\u0001"
    $tenant_id = tenant["tenant_config.id"]
  end
end

glob_res_dir  = "/opt/tomcat/content/global/2c9fb"
unless $tenant_id.nil? || $tenant_id.empty?
  content_root  = "/opt/tomcat/content/#{$tenant_id}"
end
glob_res_root = "/opt/tomcat/content/global"

directory "/opt/tomcat/content/global" do
  owner 'tomcat'
  group 'tomcat'
  mode  '0775'
  action :create
end

directory "/opt/tomcat/content/#{$tenant_id}" do
  owner 'tomcat'
  group 'tomcat'
  mode  '0775'
  action :create
end

file "/opt/global_resource.tar.gz" do
  action :delete
end

execute "globalextract" do
  command "cd #{glob_res_root}; tar -xzvf /opt/global_resource.tar.gz; chown -R tomcat:tomcat #{glob_res_root}"
  action :nothing
end

remote_file "/opt/global_resource.tar.gz" do
  source "http://yumrepo.prometheanjira.com/core/global_resource.tar.gz"
  mode   "0644"
  action :create
  not_if { Dir.exists?(glob_res_dir) }
  notifies :run, "execute[globalextract]", :immediately
end

#################################
## End Global Resource Section ##
#################################

if node['database'].attribute?('dbserver')
  mysqlserver = node['database']['dbserver']
end

solonode = node
activnodes = []
collabnodes = []
hazelnodes = []
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
    $presearch_node['collabserver_nodes'].each do |member|
      unless member['ipaddress'].nil?
        collabnodes << member['ipaddress']
      end
    end
  else
    activnodes << "127.0.0.1"
    hazelnodes << "127.0.0.1"
  end
  collab_node_count = activnodes.count
  hazelnodes = activnodes + collabnodes
  activnodes = activnodes.collect { |worker| worker }.sort.uniq.join(",")
  hazelnodes = hazelnodes.collect { |worker| worker }.sort.uniq.join(",")
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

#Rabbitmq AV_Zone Selection
if node["provider"] == "aws"
  unless node['aws'].nil? || node['aws'].empty? || node['aws']['av_zone'].nil? || node['aws']['av_zone'].empty?
    zone = node['aws']['av_zone']
    Chef::Log.info("Zone selected: #{zone}")
  end
end

rmqaddresses = ''
if Chef::Config[:solo] || "#{node['aws']}" == "" || node.chef_environment.include?("local")
  Chef::Log.warn("WARNING: Single mode or AWS AV zone unavailable.")
  rmqaddresses = "127.0.0.1:5672"
else
  $presearch_node['rabbitmq_nodes'].each do |rabbitnode|
    if rabbitnode.inspect.include?("av_zone\"=>\"#{node['aws']['av_zone']}")      
      rmqaddresses += "#{rmqaddresses}" == '' ? "" : ","
      rmqaddresses += "#{rabbitnode['ipaddress']}:5672"
    end
  end
end

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end

template "/opt/tomcat/conf/logback.xml" do
  source "activfoundation.logback.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  if node['tomcat']['logback'] == "false"
    action :delete
  end
end

tenantenv = "tenants" + "#{node.chef_environment}"
template "/opt/tomcat/conf/activfoundation.properties" do
  source "activfoundation.properties.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  notifies :restart, "service[activtomcat]"
  variables(
           :mysqlserver => mysqlserver,
           :activnodes => activnodes,
           :collab_node_count => collab_node_count,
           :hazelnodes => hazelnodes,
           :elasticnodes => elasticnodes,
	   :emailserver => mailserver["smtpserver"],
	   :emailuser => mailserver["smtpuser"],
	   :emailpass => mailserver["smtppass"],
           :tenants => $tenants,
           :reporthost => "#{node['af']['reporthost']}" == "" ? node['collab']['collabhost'] : node['af']['reporthost'],
           :rmqaddresses => rmqaddresses,
           :zkaddresses => "127.0.0.1"
           )
end

include_recipe "prom-activfoundation::logback-foundation"

include_recipe "prom-activfoundation::activfoundation-saml"

include_recipe "prom-activfoundation::aspose-lic"

template "/usr/local/sbin/monitor_logs.sh" do
  source "monitor_logs.sh.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

# IN-1291 We can eventually remove this once all environments have the update.
include_recipe "prom-activfoundation::gfcontent-update"
