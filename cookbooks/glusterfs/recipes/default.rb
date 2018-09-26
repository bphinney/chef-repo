#
# Cookbook Name:: glusterfs
# Recipe:: default
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

package "yum-plugin-priorities" do
  action :upgrade
end

execute "yumcache" do
  command "yum clean metadata; yum makecache"
  action :nothing
end

execute "remount_upgrade" do
  command "umount /opt/tomcat/content; mount /opt/tomcat/content"
  action :nothing
  only_if { Dir.exists?("/opt/tomcat/content") }
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

#Install packages for GlusterFS
unless "#{gl_version}" == ''
  %w{glusterfs glusterfs-fuse glusterfs-libs}.each do |pkg|
    yum_package pkg do
      if node['platform_version'].to_i == '7'
        version gl_version.strip + ".el7"
      else
        version gl_version.strip + ".el6"
      end
      #flush_cache [ :before ]
      action :install
      notifies :run, "execute[remount_upgrade]"
    end
  end
else 
  Chef::Log.warn("Attribute gl_version not set.")
end
