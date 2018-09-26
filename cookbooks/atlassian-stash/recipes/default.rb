#
# Cookbook Name:: atlassian-stash
# Recipe:: default
#
# Copyright 2016, Altisource
#
# All rights reserved - Do Not Redistribute
#

include_recipe "atlassian::hostsfile"
include_recipe "atlassian::selinux"
include_recipe "atlassian::default"
include_recipe "java::openjdk"

# Use AWS Snapshots for backup
aws = data_bag_item("aws-sdk", "main")
include_recipe "promaws"
if node['provider'] == "aws"
  # Install Snapshots for backups
  include_recipe "atlassian::reposnap"
end

yum_repository 'epel' do
  description 'Extra Packages for Enterprise Linux 6 - $basearch'
  mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch'
  gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
  action :create
end

package "httpd" do
  action :upgrade
end

file "/etc/httpd/conf.d/README" do
  action :delete
  only_if "test -f /etc/httpd/conf.d/README"
end

directory "/var/log/httpd" do
  recursive true
end

template "/etc/init.d/stash" do
  source "stash-init.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

service "stash" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

service "httpd" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

remote_file "/opt/stash/lib/#{node['mysqlconnector']}" do
  source "http://yumrepo.prometheanjira.com/core/#{node['mysqlconnector']}"
  mode  "0664"
  owner "stash"
  group "stash"
  action :create_if_missing
end

node['oldmysqlconnector'].each do |mysql|
  file "/opt/git/lib/#{mysql}" do
    action :delete
    only_if "test -f /opt/git/lib/#{mysql}"
    notifies :restart, "service[stash]"
  end
end

template "/opt/git/shared/bitbucket.properties" do
  source "stash-config.properties.erb"
  owner  "stash"
  group  "stash"
  mode   "0640"
  notifies :restart, "service[stash]"
end

template "/opt/stash/bin/setenv.sh" do
  source "stash.setenv.sh.erb"
  owner  "stash"
  group  "stash"
  notifies :restart, "service[stash]"
end

template "/opt/git/shared/server.xml" do
  source "stash-server.xml.erb"
  owner  "stash"
  group  "stash"
  notifies :restart, "service[stash]"
end

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/etc/httpd/conf.d/stash.conf" do
  source "httpd_rewrite.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:appname => "stash", 
            :sslRedirect => "true"
           )
  notifies :restart, "service[httpd]"
end

template "/usr/local/sbin/stash-backup" do
  source "stash-backup.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  action :delete
end

cron "stash-backup" do
  minute "05"
  hour   "04"
  command "/usr/local/sbin/stash-backup > /usr/local/sbin/stash-backup.log"
  action :delete
end

cron "stashlog_cleanup" do
  minute "0"
  hour   "0"
  day    "*"
  month  "*"
  weekday "*"
  user   "root"
  command "find /opt/git/log -name *.log -mtime +5 -exec rm -f {} \\;"
  action :create
end

cron "yumrepo-backup" do
  minute "10"
  hour   "0"
  command "/usr/local/bin/yumrepo-backup > /var/log/yumrepo-backup.log"
  action :delete
end

service "stash" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable,:start]
end

hostsfile_entry "10.0.1.220" do
  hostname "bamboodirect.prometheanjira.com"
  comment "Local hostsfile entry for Application links"
  action :create
  unique true
end

hostsfile_entry "10.0.1.132" do
  hostname "wikidirect.prometheanjira.com jiradirect.prometheanjira.com"
  comment "Local hostsfile entry for Application links"
  action :create
  unique true
end

