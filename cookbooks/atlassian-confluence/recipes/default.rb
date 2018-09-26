#
# Cookbook Name:: atlassian-confluence
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "atlassian::hostsfile"
include_recipe "atlassian::selinux"
include_recipe "prom-default"
include_recipe "java::openjdk"

%w{httpd swftools java-1.8.0-openjdk}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

file "/etc/httpd/conf.d/README" do
  action :delete
  only_if "test -f /etc/httpd/conf.d/README"
end

template "/etc/init.d/confluence" do
  source "confluence-init.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/opt/confluence/bin/setenv.sh" do
  source "confluence.setenv.sh.erb"
  owner  "confluence"
  group  "confluence"
  mode   "0755"
  notifies :restart, "service[confluence]"
end

service "confluence" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

service "httpd" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

remote_file "/opt/confluence/lib/#{node['mysqlconnector']}" do
  source "http://yumrepo.prometheanjira.com/core/#{node['mysqlconnector']}"
  mode  "0644"
  owner "confluence"
  group "confluence"
  action :create_if_missing
end

node['oldmysqlconnector'].each do |mysql|
  file "/opt/confluence/lib/#{mysql}" do
    action :delete
    only_if "test -f /opt/confluence/lib/#{mysql}"
    notifies :restart, "service[confluence]"
  end
end

%w{activation-1.0.2.jar mail-1.4.5.jar}.each do |file|
  execute file do
    command "mv /opt/confluence/confluence/WEB-INF/lib/#{file} /opt/confluence/lib/#{file}"
    only_if "test -f /opt/confluence/confluence/WEB-INF/lib/#{file}"
  end
end

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end

execute "server-xml-backup" do
  command 'mv /opt/confluence/conf/server.xml.bak /opt/confluence-data/backups/server.xml.bak-`date +%s`; cp -a /opt/confluence/conf/server.xml /opt/confluence/conf/server.xml.bak'
  only_if '[[ `diff -qN /opt/confluence/conf/server.xml /opt/confluence/conf/server.xml.bak` ]]'
  action :run
end

execute "cfg-xml-backup" do
  command 'mv /opt/confluence-data/confluence.cfg.xml.bak /opt/confluence-data/backups/confluence.cfg.xml.bak-`date +%s`; cp -a /opt/confluence-data/confluence.cfg.xml /opt/confluence-data/confluence.cfg.xml.bak'
  only_if '[[ `diff -qN /opt/confluence-data/confluence.cfg.xml /opt/confluence-data/confluence.cfg.xml.bak` ]]'
  action :run
end

template "/opt/confluence/conf/server.xml" do
  source "confluence-server.xml.erb"
  owner  "confluence"
  group  "confluence"
  mode   "0644"
  variables(
    :emailserver => mailserver["smtpserver"],
    :emailuser => mailserver["smtpuser"],
    :emailpass => mailserver["smtppass"]
  )
  notifies :restart, "service[confluence]"
end

template "/opt/confluence-data/confluence.cfg.xml" do
  source "confluence.cfg.xml.erb"
  owner  "confluence"
  group  "confluence"
  mode   "0644"
  notifies :restart, "service[confluence]"
end

template "/opt/confluence/confluence/WEB-INF/classes/confluence-init.properties" do
  source "confluence-init.properties.erb"
  owner  "confluence"
  group  "confluence"
  mode   "0644"
  notifies :restart, "service[confluence]"
end

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/etc/httpd/conf.d/wiki.conf" do
  source "httpd_rewrite.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:appname => "wiki", 
            :sslRedirect => "true"
           )
  notifies :restart, "service[httpd]"
end

template "/etc/logrotate.d/confluence" do
  source "confluence-logrotate.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  action :delete
end

cookbook_file "/opt/confluence/confluence/WEB-INF/classes/log4j.properties" do
  source "confluence-log4j.properties"
  mode   "0644"
  owner  "confluence"
  group  "confluence"
  notifies :restart, "service[confluence]"
end

cron "confluence-restart" do
  command "/sbin/service confluence restart"
  minute  "20"
  hour    "1"
  weekday "0"
end

service "confluence" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable,:start]
end

template "/opt/confluence/confluence/robots.txt" do
  source "robots.txt.erb"
  owner  "confluence"
  group  "confluence"
  mode   "0644"
end

hostsfile_entry "10.0.1.109" do
  hostname "stashdirect.prometheanjira.com"
  comment "Local hostsfile entry for Application links"
  action :create
  unique true
end

hostsfile_entry "10.0.1.220" do
  hostname "bamboodirect.prometheanjira.com"
  comment "Local hostsfile entry for Application links"
  action :create
  unique true
end

hostsfile_entry "10.0.1.132" do
  hostname "atlassian.prometheanjira.com wikidirect.prometheanjira.com jiradirect.prometheanjira.com"
  comment "Local hostsfile entry for Application links"
  action :create
  unique true
end

