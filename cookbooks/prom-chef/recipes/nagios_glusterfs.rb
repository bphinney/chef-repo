# Cookbook Name:: promethean
# Recipe:: nagios_glusterfs
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-presearch"

%w{nagios_services nagios_templates nagios_hostgroups nagios_eventhandlers}.each do |directory|
  directory "/root/data_bags/#{directory}" do
    recursive true
  end
end

nfsserver = []
nfsservers = []
nfshosts = []
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  $presearch_node['nfs_primaries'].each do |server|
    nfsserver << server['ipaddress']
  end
  nfsserver=nfsserver.first
  $presearch_node['nfs_servers'].each do |server|
    nfsservers << server
    nfshosts << server['hostname']
  end
end

execute "hostgroup_upload" do
  command "knife data bag from file nagios_hostgroups /root/data_bags/nagios_hostgroups/glusterfs-monitor.json"
  action :nothing
end

template "/root/data_bags/nagios_hostgroups/glusterfs-monitor.json" do
  source "glustermon-hostgroup.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[hostgroup_upload]"
  variables( :hostname => nfshosts.sort.first )
end

execute "template_upload" do
  command "knife data bag from file nagios_templates /root/data_bags/nagios_templates/glusterfs-check.json"
  action :nothing
end

template "/root/data_bags/nagios_templates/glusterfs-check.json" do
  source "glusterfs_template.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[template_upload]"
end

execute "eventhandler_upload" do
  command "knife data bag from file nagios_eventhandlers /root/data_bags/nagios_eventhandlers/remount-volume.json"
  action :nothing
end

template "/root/data_bags/nagios_eventhandlers/remount-volume.json" do
  source "remount-volume.json.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[eventhandler_upload]"
end

noenvirons = node['gluster']['noenvirons']
# Collate a list of non-excluded environments for shared filesystem
environs = []
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  $presearch_envs.each do |environment|
    unless noenvirons.any?{ |str| environment['envname'].include? str }
      environs << environment['envname']
    end
  end
  environs = environs.sort.uniq
end

# Create data bags for AF Content
environs.each do |dir|
  serverhash = nfshosts.collect { |server| "#{server}:/export/content#{dir}"}
  execute "dataup-content#{dir}" do
    command "knife data bag from file nagios_services /root/data_bags/nagios_services/content#{dir}.json"
    action :nothing
  end
  template "/root/data_bags/nagios_services/content#{dir}.json" do
    source "check_glusterfs.erb"
    variables(
      :volume => "content#{dir}",
      :bricks => "#{serverhash.count}"
    )
    notifies :run, "execute[dataup-content#{dir}]"
   end
end
