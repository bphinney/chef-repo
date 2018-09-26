#
# Cookbook Name:: promethean
# Recipe:: s3fs
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default::repo"

# IN-1186 Updated to convert to data bag items
begin
  s3fsbackup = data_bag('glusterfs')
    rescue Net::HTTPServerException
      Chef::Log.info("No data bag glusterfs")
end

unless s3fsbackup.nil? || s3fsbackup.empty?
  package "s3fs" do
    action :upgrade
  end
  
  link "/usr/bin/s3fs" do
    to "/usr/sbin/s3fs.bin"
  end

  bucketurls = []
  buckets = data_bag('glusterfs')
  buckets.each do |bucket|
    bucketdata = data_bag_item('glusterfs', bucket)
    bucketurls << "#{bucketdata['bucket']}:#{bucketdata['aws_access_key_id']}:#{bucketdata['aws_secret_access_key']}"
  end                
  template "/etc/passwd-s3fs" do
    source "passwd-s3fs.erb"
    owner  "root"
    group  "root"
    mode   "0640"
    variables(:bucketurls => bucketurls)
  end
  
  buckets.each do |bucket|
    s3fscred = data_bag_item('glusterfs', bucket)
    mountdir = s3fscred['mountdir']
    directory mountdir do
      owner "root"
      group "root"
      recursive true
      action :create
      not_if { Dir.exist?("#{mountdir}") || s3fscred["bucket"].nil? || s3fscred["bucket"].empty? }
    end

    mount mountdir do
      mount_point mountdir
      device "s3fs##{s3fscred['bucket']}"
      options "allow_other,_netdev,nodev,nonempty,suid"
      dump 0
      pass 0
      fstype "fuse"
      action [:enable, :mount]
      not_if { IO.read("/proc/mounts").include?("#{mountdir}") || s3fscred["bucket"].nil? || s3fscred["bucket"].empty? }
    end

  end

  template "/usr/local/sbin/s3_backup" do
    source "s3_backup.erb"
    owner  "root"
    group  "root"
    mode   "0755"
    #variables(:bucketName => s3fscred["bucket"] )
  end

  cron "s3backup" do
    command "/usr/local/sbin/s3_backup > /var/log/s3_backup.log 2>&1"
    minute "25"
    hour   "2"
    weekday "6"
  end

end
