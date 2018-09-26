#
# Cookbook Name:: glusterfs
# Recipe:: contentback-remove
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
if node['af']['content_fallback'] == "remove"

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

    mount "glusterfs" do
    mount_point "/opt/tomcat/contentback"
    device "#{nfsserver.first}:/content#{node.chef_environment}"
    options "defaults,_netdev,backupvolfile-server=#{nfsserver.last}"
    fstype "glusterfs"
    action [:disable, :umount]
    dump 0
    pass 0
  end

  #execute "umount" do
  #  command "umount /opt/tomcat/contentback"
  #  action :run
  #  only_if "grep #{nfsserver.first}:/content#{node.chef_environment} /etc/mtab"
  #end

  directory "/opt/tomcat/contentback" do
    action :delete
    only_if "ls /opt/tomcat/contentback == ''"
  end
end
