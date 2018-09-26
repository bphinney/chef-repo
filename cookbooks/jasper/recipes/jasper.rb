#
# Cookbook Name:: promethean
# Recipe:: jasper
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "java::openjdk"
include_recipe "prom-default::hostsfile"

if node['platform_version'].to_i == '7' 
  template '/usr/lib/systemd/system/jasper.service' do
    source 'jasper-init.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end 
  link '/etc/systemd/system/jasper.service' do
    to '/usr/lib/systemd/system/jasper.service'
  end 
else
  template "/etc/init.d/jasper" do
    source "jasper-init.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end 
end

remote_file "/opt/jasper/apache-tomcat/lib/mysql-connector-java-5.1.34.jar" do
  source "http://#{node['yum']['yumserver']}/core/mysql-connector-java-5.1.34.jar"
  owner  "root"
  group  "root"
  mode   "0755"
  not_if { File.exists?("/opt/jasper/apache-tomcat/lib/mysql-connector-java-5.1.34.jar") }
end

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end

template "/opt/jasper/apache-tomcat/webapps/#{node['jasper']['servertype']}/WEB-INF/js.quartz.properties" do
  source "js.quartz.properties.erb"
  user   "root"
  group  "root"
  mode   "0644"
  variables(
    :emailserver => mailserver['smtpserver'],
    :emailuser => mailserver['smtpuser'],
    :emailpass => mailserver['smtppass']
  )
end
