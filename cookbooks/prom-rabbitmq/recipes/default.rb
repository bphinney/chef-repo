#
# Cookbook Name:: prom-rabbitmq
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Include prom-default items
include_recipe "prom-default"
include_recipe "promaws::default"

#Newrelic Plugin
if node['newrelic']["newrelic-plugin-install"] == "true"
  include_recipe "prom-newrelic::newrelic-plugin"
end

# Ensure SELinux is disabled to allow port to open
include_recipe "prom-default::selinux"

node.default['rabbitmq']['mnesiadir'] = "/opt/rabbitmq/mnesia"
node.default['rabbitmq']['default_user'] = 'bugsbunny'
node.default['rabbitmq']['default_pass'] = 'wascallywabbit'

yum_package "socat" do
  action :upgrade
end

if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  rabbitnodes = []
  unless node.chef_environment.include?("local")
    include_recipe "prom-presearch"
    $presearch_node['rabbitmq_cluster'].each do |rabbitnode|
      rabbitnodes << rabbitnode['hostname']
    end  
  else
    rabbitnodes << "localhost"
  end
    rabbitnodes = rabbitnodes.sort!
    rabbitcluster = rabbitnodes.collect { |entry| "rabbit@#{entry}"}
end

#Add entry in hostsfile for all cluster members.
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
elsif node.chef_environment.include?("local")
  Chef::Log.warn("This server is a local environment, no hostname needed.")
else
  include_recipe "prom-presearch"
  $presearch_node['rabbitmq_cluster'].each do |rabbitnode|
    hostsfile_entry rabbitnode['ipaddress'] do
      hostname rabbitnode['hostname']
      comment "Updated by Chef"
      action :create
      unique true
      only_if { node['serveraddress'].nil? || node['serveraddress'].empty? }
    end
  end
end

# Fix for upstart to systemd change - take the upstart script and
# move it to the bin directory, then explicitly create the service file for 
# systemd.  

if node['platform_version'].to_i == '7' 
  cookbook_file "/usr/lib/systemd/system/rabbitmq-server.service" do
    user "root"
    group "root"
    mode "0755"
    source "rabbitmq-service-systemd"
  end 
end

node.default['rabbitmq']['cluster_disk_nodes'] = rabbitcluster
unless node.chef_environment.include?("local")
  node.default['rabbitmq']['cluster'] = "true"
else
  node.default['rabbitmq']['cluster'] = "false"
end

noenvirons = node['noenvirons']
#virtualhosts
if Chef::Config[:solo] 
  environs = []
  environs << node.chef_environment
elsif node.chef_environment.include?("local")
  environs = []
  environs << node.chef_environment
else
  environs = []
  search(:environment, "name:*").each do |environment|
    unless noenvirons.any?{ |str| environment.name.include? str }
      environs << environment.name
    end
  end
end

if Chef::Config[:solo]
  Chef::Log.warn("In solo mode, can not sort environs.")
else
  environs = environs.sort.uniq
end

vhosts = []
environs.each do |environ|
  vhosts << "/activfoun#{environ}"
end
node.default['rabbitmq']['virtualhosts'] = vhosts

disabled_vhosts = []
unless node['rabbitmq']['disabled_vhosts'].nil? || node['rabbitmq']['disabled_vhosts'].empty?
  node['rabbitmq']['disabled_vhosts'].each do |disvhost|
    disabled_vhosts << "/activfoun#{disvhost}"
  end
  node.default['rabbitmq']['disabled_virtualhosts'] = disabled_vhosts
end

#users
enabled_users = []
environs.each do |environ|
  enabled_users << { :name => "rabbituser#{environ}", :password => "rabbitpass#{environ}", :rights => [{:vhost => "/activfoun#{environ}" , :conf => ".*", :write => ".*", :read => ".*"}] }
  enabled_users << { :name => "bugsbunny", :password => "wascallywabbit", :rights => [{:vhost => "/activfoun#{environ}" , :conf => ".*", :write => ".*", :read => ".*"}], :tag => "administrator" }
end

node.default['rabbitmq']['enabled_users'] = enabled_users 
#plugins
node.default['rabbitmq']['enabled_plugins'] = [ "rabbitmq_shovel" ]

#HA policies

#Setting vhost defaults for the default vhost policies.
vhosts.each do |vhost|
  node.default['rabbitmq']['policies']["ha-#{vhost}"]['pattern'] = "^ha."
  node.default['rabbitmq']['policies']["ha-#{vhost}"]['params'] = { "ha-mode" => "all" }
  node.default['rabbitmq']['policies']["ha-#{vhost}"]['priority'] = 0
  node.default['rabbitmq']['policies']["ha-#{vhost}"]['vhost'] = vhost
end

node.default['rabbitmq']['disabled_policies'] = [ "ha-all", "ha-two" ]
node.default['rabbitmq']['policies'].delete('ha-all')
node.default['rabbitmq']['policies'].delete('ha-two')

# Install the rabbit-mq admin cli tool
# This section moved into the rabbitmq-admin recipe so that we can run it later.
#remote_file '/usr/local/bin/rabbitmqadmin' do
#  source 'http://localhost:15672/cli/rabbitmqadmin'
#  mode '0755'
#  action :create
#  ignore_failure true
#end

execute "reduce-rabbit-backlog" do
  command "sed -i 's/rotate .*/rotate 2/g' /etc/logrotate.d/rabbitmq-server && find /var/log/rabbitmq/*.gz -type f -mmin +20160 | xargs -I {} rm {}"
  action :run
  only_if "test -f /etc/logrotate.d/rabbitmq-server"
  not_if "grep -q \"rotate 2$\" /etc/logrotate.d/rabbitmq-server"
end

# Let's remove old queues found under env::default_attributes::rabbitmq_queues
resultData = search(:environment, "rabbitmq_queues:*",
	       :filter_result => { 
               'vhost' => ['default_attributes','rabbitmq_queues','vhost'],
               'deleted_queues' => ['default_attributes','rabbitmq_queues','deleted_queues']
               })

resultData.each do |item|
  v = item['vhost']; q = item['deleted_queues']
  q.split(" ").each { |queue| 
    prom_rabbitmq_rabbitctl v do
      queue queue
      action :delete_queue
    end
  }
end

include_recipe "prom-rabbitmq::rabbitmq-clean"
