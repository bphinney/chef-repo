#
# Cookbook Name:: glusterfs
# Recipe:: efs-af
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

#Install packages for NFS
package "nfs-utils" do
  action :upgrade
end
  
directory "/opt/tomcat/content" do
  owner   "tomcat"
  group   "tomcat"
  recursive true
end


# Check for EFS filesystem if it exists,
unless node['efs']['target'].nil? || node['efs']['target'].empty?
  execute "fstab_check" do
    command "fscheck=`grep /opt/tomcat/content /etc/fstab | grep -v #{node['aws']['av_zone']}.#{node['efs']['target']}:/content#{node.chef_environment}`; if [ \"$fscheck\" != \"\" ]; then umount /opt/tomcat/content; sed -i '/opt\\/tomcat\\/content/d' /etc/fstab; fi"
    action :run
    only_if "grep /opt/tomcat/content /etc/fstab | grep -v #{node['aws']['av_zone']}.#{node['efs']['target']}:/content#{node.chef_environment}"
  end
end

# Mount EFS filesystem if it exists
unless node['efs']['target'].nil? || node['efs']['target'].empty?
  mount "efs" do
    mount_point "/opt/tomcat/content"
    device "#{node['aws']['av_zone']}.#{node['efs']['target']}:/content#{node.chef_environment}"
    options "defaults"
    fstype "nfs"
    action [:mount, :enable]
    dump 0
    pass 0
  end
end

# Remount command, If EFS Filesystem target exists
unless node['efs']['target'].nil? || node['efs']['target'].empty?
  execute "remount" do
    command "umount /opt/tomcat/content; mount /opt/tomcat/content"
    action :run
    not_if "grep #{node['aws']['av_zone']}.#{node['efs']['target']}:/content#{node.chef_environment} /etc/mtab"
  end
end

if node['af']['content_fallback'] == "true"
  include_recipe "glusterfs::glusterfs-contentback"
elsif node['af']['content_fallback'] == "remove"
  include_recipe "glusterfs::contentback-remove"
end
