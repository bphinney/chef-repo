#
# Cookbook Name:: glusterfs
# Recipe:: efs-backup
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::default"
include_recipe "promaws::default"

#Install packages for NFS
package "nfs-utils" do
  action :upgrade
end

#Install rsync for backup
package "rsync" do
  action :upgrade
end
  
directory "/efs/data" do
  owner   "root"
  group   "root"
  recursive true
end

directory "/efs/backup" do
  owner   "root"
  group   "root"
  recursive true
end


# Check for EFS filesystem
unless node['efs']['target'].nil? || node['efs']['target'].empty?
  execute "fstab_check" do
    command "fscheck=`grep /efs/data /etc/fstab | grep -v #{node['aws']['av_zone']}.#{node['efs']['target']}/`; if [ \"$fscheck\" != \"\" ]; then sed -i '/efs\\/data/d' /etc/fstab; fi"
    action :run
    only_if "grep /efs/data /etc/fstab | grep -v #{node['aws']['av_zone']}.#{node['efs']['target']}:/"
  end
end

# Check for EFS Backup filesystem
unless node['efs']['backup'].nil? || node['efs']['backup'].empty?
  execute "fstab_check" do
    command "fscheck=`grep /efs/backup /etc/fstab | grep -v #{node['aws']['av_zone']}.#{node['efs']['backup']}/`; if [ \"$fscheck\" != \"\" ]; then sed -i '/efs\\/backup/d' /etc/fstab; fi"
    action :run
    only_if "grep /efs/backup /etc/fstab | grep -v #{node['aws']['av_zone']}.#{node['efs']['backup']}:/"
  end
end

# Mount EFS filesystem if it exists
unless node['efs']['target'].nil? || node['efs']['target'].empty?
  mount "efs" do
    mount_point "/efs/data"
    device "#{node['aws']['av_zone']}.#{node['efs']['target']}:/"
    options "defaults"
    fstype "nfs"
    action [:mount, :enable]
    dump 0
    pass 0
  end
end

# Mount EFS Backup filesystem if it exists
unless node['efs']['backup'].nil? || node['efs']['backup'].empty?
  mount "efs" do
    mount_point "/efs/backup"
    device "#{node['aws']['av_zone']}.#{node['efs']['backup']}:/"
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
    not_if "grep #{node['aws']['av_zone']}.#{node['efs']['target']}:/ /etc/mtab"
  end
end

# Remount command, If EFS Filesystem Backup exists
unless node['efs']['backup'].nil? || node['efs']['backup'].empty?
  execute "remount" do
    command "umount /efs/backup; mount /efs/backup"
    action :run
    not_if "grep #{node['aws']['av_zone']}.#{node['efs']['backup']}:/ /etc/mtab"
  end
end

unless node['efs']['backup'].nil? || node['efs']['backup'].empty?
  template "/usr/local/sbin/efs_backup" do
    source "efs_backup.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end

  cron "efsbackup" do
    command "/usr/local/sbin/efs_backup > /var/log/efs_backup.log 2>&1"
    minute  "25"
    hour    "2"
    weekday "6"
  end
end

