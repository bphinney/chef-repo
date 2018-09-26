#
# Cookbook Name:: atlassian-yumrepo
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "atlassian::hostsfile"
include_recipe "prom-default::yumepel"
include_recipe "prom-http::default"
include_recipe "promaws"

service "httpd" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

directory "/opt/yum-repo/apt" do
  action :create
  not_if "test -d /opt/yum-repo/apt"
end

%w{dists/stable/main/binary-amd64 stable/main/binary-i386 pool/main}.each do |dir|
  directory "/opt/yum-repo/apt/#{dir}" do
    recursive true
    action :create
    not_if "test -d /opt/yum-repo/apt/#{dir}"
  end
end

%w{common core testing release special common7 special7 ActivConnect ActivConnectDev TestFlight cfserver}.each do |dir|
  directory "/opt/yum-repo/#{dir}" do
    recursive true
    action :create
    not_if "test -d /opt/yum-repo/#{dir}"
  end
end

template "/usr/local/bin/reindex_stable.sh" do
  source "reindex_stable.sh.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

link "/usr/bin/reindex_stable.sh" do
  to "/usr/local/bin/reindex_stable.sh"
end

template "/etc/httpd/conf.d/yumrepo.conf" do
  source "yumrepo.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/usr/bin/yumrepo-update" do
  source "yumrepo-update.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/usr/local/bin/purge-rpm" do
  source "purge-rpm.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

cron "yumrepo_update" do
  command "/usr/bin/yumrepo-update > /var/log/yumrepo-update.log 2>&1"
  minute "10,50"
  hour   "*"
  action :create
end

cron "purgerpm" do
  command "/usr/local/bin/purge-rpm > /var/log/purge-rpm.log 2>&1"
  minute "10"
  hour   "2"
  day    "5"
  action :create
end

# Install Snapshots for backups
include_recipe "atlassian::reposnap"

# Include gpg key configuration
include_recipe "atlassian-yumrepo::yumrepo-gpg"
