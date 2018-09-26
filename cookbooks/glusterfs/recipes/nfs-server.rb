#
# Cookbook Name:: promethean
# Recipe:: nfs-server
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "prom-presearch"
include_recipe "prom-default::selinux"

execute "yumcache" do
  command "yum clean metadata; yum makecache"
  action :nothing
end

package "yum-plugin-priorities" do
  action :upgrade
end

#Set Gluster version for install
gl_version = node['gluster']['gluster_version']
gl_major = gl_version.split('.')[0]
gl_minor = gl_version.split('.')[1]
gl_build = gl_version.split('-')[0]
gl_branch = "#{gl_major}.#{gl_minor}"
Chef::Log.info("gluster branch is #{gl_branch}, gluster build is #{gl_build}.")
template "/etc/yum.repos.d/glusterfs-epel.repo" do
  source "glusterfs-epel.repo.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables( :glusterbranch => gl_branch, :glusterbuild => gl_build )
  notifies :run, "execute[yumcache]", :immediately
end

#nfsserver  = []
nfsservers = []
nfshosts   = []
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  $presearch_node['gluster_nodes'].each do |server|
    nfsservers << server
  end
  nfsservers.each do |server|
    nfshosts << server['hostname']
    hostsfile_entry server['ipaddress'] do
      hostname server['hostname']
      action :create
      unique true
    end
  end
end

###Logic for nomination automation of the Glusterfs primary node
nfsprimary = []
$presearch_node['gluster_primary'].each do |server|
  nfsprimary << server
end 
if nfsprimary.nil?
  node.normal['nfs-server'] = 'primary'
elsif nfsprimary.count > 1
  node.rm('nfs-server')
end


#Install packages for GlusterFS
gluster_version = node['gluster']['gluster_version']
unless "#{gluster_version}" == ''
  %w{glusterfs-server glusterfs-fuse glusterfs-libs}.each do |pkg|
    yum_package pkg do
      if node['platform_version'].to_i == '7'
        version gl_version.strip + ".el7"
      else
        version gl_version.strip + ".el6"
      end
      #flush_cache [ :before ]
      action :install
      notifies :restart, "service[glusterd]"
    end
  end
  %w{fuse fuse-libs nfs-utils}.each do |nfspkg|
    yum_package nfspkg do
      action :upgrade
      notifies :restart, "service[glusterd]"
    end
  end
else 
  Chef::Log.warn("Attribute gluster_version not set.")
end

# GlusterFS services
%w{glusterd}.each do |service|
  service service do
    supports :stop => true, :start => true, :restart => true, :status => true, :enable => true
    action :nothing
  end
end

include_recipe "promaws::default"
aws = data_bag_item("aws-sdk", "main")
unless node['gluster']['gluster_volume'].nil? || node['gluster']['gluster_volume'].empty?
# Create and attach volume
  node['gluster']['gluster_volume'].each do |device,size|
    aws_ebs_volume `hostname`.strip! + "-gfs_vol" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      size size
      device device
      volume_type "gp2"
      region node['aws_node_region'] if node['requires_aws_region']
      action [ :create, :attach ]
    end
  end
end

package "xfsprogs" do; action :install; end
package "bc" do; action :install; end

mountpoints = []
node['gluster']['gluster_mount'].each do |mount,device|
  directory mount do
    action :create
  end
  bash "Format device: #{device}" do
      __command = "mkfs.xfs #{device}"
      __fs_check = 'blkid'

      code __command

      not_if "#{__fs_check} #{device}"
  end
  mount mount do
    device device
    fstype "xfs"
    options "noatime"
    action [:enable, :mount]
  end
  mountpoints << mount
end
serverhash = []

serverhash = serverhash.collect { |brick| brick }.join(" ")
Chef::Log.info("Content volume would be created with #{serverhash}")

noenvirons = node['gluster']['noenvirons']
#Environments for Activfoundation Shared filesystem
backenvirons = []
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
else
  search( :environment, "content_storage:true" ).each do |environment|
    unless noenvirons.any?{ |str| environment.name.include? str }
      backenvirons << environment.name
    end
  end
  backenvirons = backenvirons.sort.uniq
end

%w{storage content backup}.each do |dir|
  directory "/opt/#{dir}" do
    owner "root"
    group "root"
    recursive true
  end
end
# Mount and format EBS Volume here - end

# Peer Probe operations
nfsservers.each do |server|
  execute "peer-server-#{server['hostname']}" do
    command "/usr/sbin/gluster peer probe #{server['hostname']}"
    action :run
    not_if { || server['hostname'] == node['hostname'] }
  end
end

# For Individual Environment Content Volumes 
backenvirons.each do |env|
  serverhash = nfshosts.collect { |server| "#{server}:/export/content#{env}"}.join(" ")
  execute "gluster-content#{env}-export" do
    command "gluster volume create content#{env} replica #{nfsservers.count} #{serverhash}; gluster volume start content#{env}; gluster volume set content#{env} cluster.readdir-optimize on"
    not_if "gluster volume info content#{env}"
  end
end

%w{glusterd}.each do |service|
  service service do
    supports :stop => true, :start => true, :restart => true, :status => true
    action [:enable, :start]
  end
end

service "glusterfsd" do
  supports :stop => true, :start => true, :restart => true, :status => true
  action [:enable]
end

template "/usr/local/bin/gfid-resolver" do
  source "gfid-resolver.erb"
  owner "root"
  group "root"
  mode "0755"
#  only_if { node['nfs-server'] == "primary" }
end

include_recipe "glusterfs::nfs-server-snap"

  
