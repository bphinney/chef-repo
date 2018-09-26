#
# Cookbook Name:: glusterfs
# Recipe:: glusterfs-af
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Check for EFS filesystem if it exists, else glusterfs
unless node['efs']['target'].nil? || node['efs']['target'].empty?
  include_recipe "glusterfs::efs-af"
else
  
  directory "/opt/tomcat/content" do
    owner   "tomcat"
    group   "tomcat"
    recursive true
  end

  include_recipe "glusterfs::default"

  nfsserver = []

  if node.attribute?('nfsserver') 
    nfsserver = node['nfsserver']
  end

  if nfsserver.nil? || nfsserver.empty?
    if (Chef::Config[:solo] || node.chef_environment.include?("local"))
      Chef::Log.warn("Excluding NFS-SERVER hostsfile entry in local/solo mode")
    else
      nfsserverenv = []
      unless node['gluster_env'].nil? || node['gluster_env'].empty?
        $presearch_node['gluster_servers'].each do |server|
          nfsserverenv << server['ipaddress']
        end
      else
        $presearch_node['gluster_nodes'].each do |server|
          nfsserverenv << server['ipaddress']
        end
      end
      nfsserver = nfsserverenv
      #nfsserver=nfsserver.first
      unless node['gluster_nfsserver'].nil? || node['gluster_nfsserver'].empty?
        nfsserver=node['gluster_nfsserver']
      end
      $presearch_node['all_nfsservers'].each do |server|
        hostsfile_entry server['ipaddress'] do
          hostname server['hostname']
          action :create
          unique true
        end
      end
    end
  end
  nfsserver = nfsserver.sort

  execute "fstab_check" do
    command "fscheck=`grep /opt/tomcat/content /etc/fstab | grep -v #{nfsserver.first}:/content`; if [ \"$fscheck\" != \"\" ]; then sed -i '/opt\\/tomcat\\/content/d' /etc/fstab; fi"
    action :run
    only_if "grep /opt/tomcat/content /etc/fstab | grep -v #{nfsserver.first}:/content"
  end

  mount "glusterfs" do
    mount_point "/opt/tomcat/content"
    device "#{nfsserver.first}:/content#{node.chef_environment}"
    options "defaults,_netdev,backupvolfile-server=#{nfsserver.last}"
    fstype "glusterfs"
    action [:enable, :mount]
    dump 0
    pass 0
  end

  execute "remount" do
    command "umount /opt/tomcat/content; mount /opt/tomcat/content"
    action :run
    not_if "grep #{nfsserver.first}:/content#{node.chef_environment} /etc/mtab"
  end

  template "/etc/logrotate.d/glusterfs-common" do
    source "logrotate-glusterfs-common.erb"
    owner  "root"
    group  "root"
    mode   "0644"
    action :delete
  end
end
