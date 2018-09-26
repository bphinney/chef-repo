#
# Cookbook Name:: atlassian
# Recipe:: s3dist
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#

s3dist = data_bag_item("atlassian", "s3dist")
unless s3dist.nil? || s3dist.empty?
  package "s3fs" do
    action :upgrade
  end

  link "/usr/bin/s3fs" do
    to "/usr/sbin/s3fs.bin"
  end

  bucketurls = []
  buckets = data_bag('atlassian')
  buckets.each do |bucket|
    bucketdata = data_bag_item('atlassian', bucket)
    bucketurls << "#{bucketdata['bucket']}:#{bucketdata['aws_access_key_id']}:#{bucketdata['aws_secret_access_key']}"
  end 
  template "/etc/passwd-s3fs" do
    source "passwd-s3fs.erb"
    owner  "root"
    group  "root"
    mode   "0640"
    variables(:bucketurls => bucketurls)
    #variables(:bucketName => s3dist["bucket"],
    #          :accessKeyId => s3dist['aws_access_key_id'],
    #          :secretAccessKey => s3dist['aws_secret_access_key']
    #         )
    #not_if { s3dist["bucket"].nil? || s3dist["bucket"].empty? }
  end
  buckets.each do |bucket|  
    s3dist = data_bag_item('atlassian', bucket)
    mountdir = s3dist["mountdir"]
    directory mountdir do
      owner "root"
      group "root"
      recursive true
      action :create
      not_if { Dir.exist?("#{mountdir}") || s3dist["bucket"].nil? || s3dist["bucket"].empty? }
    end

    mount mountdir do
      mount_point mountdir
      device "s3fs##{s3dist['bucket']}"
      options "allow_other,_netdev,nodev,nonempty,suid"
      dump 0
      pass 2
      fstype "fuse"
      action [:enable, :mount]
      not_if { IO.read("/proc/mounts").include?("#{mountdir}") || s3dist["bucket"].nil? || s3dist["bucket"].empty? } 
      #not_if { "grep -qa '#{mountdir} ' /proc/mounts" }
    end
  end
end
