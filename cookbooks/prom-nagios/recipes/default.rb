#
# Cookbook Name:: prom-nagios
# Recipe:: default
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::selinux"
include_recipe "prom-default::hostsfile_update"
include_recipe "prom-presearch"
##This is handled currently by apache2 recipe
#include_recipe "prom-http::worker"

if node['platform_version'].to_i == '7'
  package "fcgi-devel" do
    action :upgrade
  end
end

%w{nagios nagios-common perl-Monitoring-Plugin}.each do |package|
  package package do
    action :upgrade
  end
end

cookbook_file "/etc/init.d/nagios" do
  source "nagios-init"
  owner  "root"
  group  "root"
  mode   "0755"
end

directory "/var/run/nagios" do
  owner "nagios"
  group "nagios"
end

directory "/usr/lib64/nagios/plugins/eventhandlers" do
  owner "nagios"
  group "nagios"
end

file "/var/run/nagios.pid" do
  owner  "nagios"
  group  "nagios"
  mode   "0644"
end

template "/usr/share/nagios/html/config.inc.php" do
  source "config.inc.php.erb"
  owner  "nagios"
  group  "apache"
  mode   "0640"
end

template "/usr/lib64/nagios/plugins/eventhandlers/event_handler_script.sh" do
  source "event_handler_script.sh.erb"
  owner  "nagios"
  group  "nagios"
  mode   "0755"
end
  
# IN-347 - Explicit inclusion of nagios-plugins-nrpe component for check_nrpe
%w{nagios-plugins-all nagios-plugins-nrpe cyrus-sasl-plain postfix perl-Nagios-Plugin perl-libwww-perl perl-JSON perl-Math-Calc-Units mailx}.each do |package|
  package package do
    action :upgrade
  end
end

if node['platform_version'].to_i == '7'
#  %w{nginx unzip}.each do |morepackage|
   %w{unzip}.each do |morepackage|
    package morepackage do
      action :upgrade
    end
  end
end

link "/etc/httpd/mods-enabled/cgi.load" do
  to "/etc/httpd/mods-available/cgi.load"
  only_if "test -f /etc/httpd/mods-available/cgi.load"
end

#remote_file "/usr/lib64/nagios/nagios-rabbitmq-plugins.zip" do
#  source "http://yumrepo.prometheanjira.com/core/nagios-rabbitmq-plugins.zip"
#end

#execute "rabbitmq_plugin_install" do
#  command "cd /usr/lib64/nagios/plugins; unzip ../nagios-rabbitmq-plugins.zip"
#  creates  "/usr/lib64/nagios/plugins/check_rabbitmq_server"
#  action :run
#  only_if "test -f /usr/lib64/nagios/nagios-rabbitmq-plugins.zip"
#end
yum_package "nagios-plugins-rabbitmq" do
  action :upgrade
end

include_recipe "prom-mailrelay::mailrelay"

if node['nagios']['exclude_string'].nil?
  node.default['nagios']['exclude_string'] = "local"
end 

# Find environments to search if excluding environments
unless node['nagios']['nomonitoring'].nil? || node['nagios']['nomonitoring'].empty?
  noenvirons = node['nagios']['nomonitoring']
  mon_environs = []
  $presearch_envs.each do |environment|
    unless noenvirons.any?{ |str| environment['envname'] == str }
      mon_environs << environment['envname']
    end
  end
  mon_environs = mon_environs.sort.uniq
end
node.override['nagios']['monitored_environments'] = mon_environs

