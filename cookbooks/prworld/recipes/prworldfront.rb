#
# Cookbook Name:: promethean
# Recipe:: prworldfront
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "prom-default::selinux"
include_recipe "prom-presearch::default"
include_recipe "prom-default::hostsfile"

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.default['newrelic']['application_monitoring']['app_name'] = "classflow"
end

#Newrelic Plugin
if node['newrelic']["newrelic-plugin-install"] == "true"
  include_recipe "prom-newrelic::newrelic-plugin"
end

# Performs default http actions
include_recipe "prom-http::default"

service 'httpd' do
  if node['platform_version'].to_i == '7' 
    stop_command '/bin/systemctl stop httpd'
    start_command '/bin/systemctl start httpd'
    reload_command '/usr/sbin/apachectl graceful'
    restart_command '/bin/systemctl restart'
  else
    stop_command "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end 
  supports :stop => true, :start => true, :restart => true, :status => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

##################################
## Start of prworld installation ##
##################################

directory "/opt/www/prworld" do
  recursive true
end

template "/etc/httpd/conf.d/prworld.conf" do
  source "prworld.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  if node['prworld']['prworld_install'] == "false"
    action :delete
  elsif node['prworld']['prworld_install'] == "true"
    action :create
  end
  notifies :run, "execute[configcheck]"
  variables( :countryblock => node['countryblock'].split(",")
  )
end

template "/etc/httpd/conf.d/prworldmulti.load" do
  source "prworld_multi.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
  variables( :prworldtenants => node['prworld']['multitenant'] )
  not_if { node['prworld']['multitenant'].nil?  || node['prworld']['multitenant'].empty? }
end

template "/etc/httpd/conf.d/prmaintenance.conf" do
  source "prmaintenance.conf.erb"
  owner  "root"
  group  "root"
  notifies :run, "execute[configcheck]"
  not_if { node['applications']['prmaint_version'] == "0.0.0-1" or node['applications']['cmsplugin']['prmaint_version'] == "0.0.0-1"}
end

prworldworkers = []
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  $presearch_node['prworld_nodes'].each do |worker|
    prworldworkers << worker
  end
end

prworldworkers.uniq! { |a| a.ipaddress }
prworldworkers.sort! { |a,b| a.ipaddress <=> b.ipaddress }
template "/etc/httpd/conf.d/prworld.proxy" do
  source "prworld.proxy.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[configcheck]"
  variables(:prworldworkers => prworldworkers,
            :countryblock => node['countryblock'].split(",")
           )
  not_if {prworldworkers.nil? || prworldworkers.empty?}
end

include_recipe "prom-http::update_htaccess"

##################################
## End of prworld installation  ##
##################################

include_recipe "prworld::prworldfront-elb"

#Section to install synapticmash if attribute exists
unless node['apache']['synapticmash_install'].nil? || node['apache']['synapticmash_install'].empty? || node['apache']['synapticmash_install'] == "false"
  include_recipe "prworld::synapticmash"
end

#Section to install prometheankb if attribute exists
unless node['prometheankb']['prometheankb_install'].nil? || node['prometheankb']['prometheankb_install'].empty? || node['prometheankb']['prometheankb_install'] == "false"
  include_recipe "prworld::prometheankb"
end

#Section to install activwallsystem if attribute exists
unless node['activwallsystem']['aw_install'].nil? || node['activwallsystem']['aw_install'].empty? || node['activwallsystem']['aw_install'] == "false"
  include_recipe "prworld::activwallsystem"
end

#Sectionto install supportmega if attribute exists
unless node['supportmega']['supportmega_install'].nil? || node['supportmega']['supportmega_install'].empty? || node['supportmega']['supportmega_install'] == "false"
  include_recipe "prworld::supportmegasite"
end

include_recipe "prworld::prmaintenance"

