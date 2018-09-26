#
# Cookbook Name:: promethean
# Recipe:: localdns
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
template "/etc/dhcp/dhclient-eth0.conf" do
  source "dhclient-eth0.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  only_if "ifconfig eth0"
end

template "/etc/dhcp/dhclient-em1.conf" do
  source "dhclient-em1.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  only_if "ifconfig em1"
end

unless node['serveraddress'].nil? || node['serveraddress'].empty?
  %w{mysql.classflow.lan backend-localdemo1 backend-localdemo}.each do |hname|
    hostsfile_entry node['serveraddress'] do
      hostname hname
      action :create
    end
  end
end
