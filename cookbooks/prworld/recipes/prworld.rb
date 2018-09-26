#
# Cookbook Name:: prworld
# Recipe:: prworld
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "java::openjdk"
include_recipe "prom-default"
include_recipe "prom-default::repo"

# Create local hosts file entry for our own IP address
include_recipe "prom-default::hostsfile"

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.override['newrelic']['application_monitoring']['app_name'] = "dotcms"
end

execute "plugininstall" do
  if node['platform_version'].to_i == '7'
    command "systemctl stop dotcms; su -c '/opt/dotCMS/bin/deploy-plugins.sh' tomcat; systemctl start dotcms"
  else
    command "service dotcms stop; su -c '/opt/dotCMS/bin/deploy-plugins.sh' tomcat; service dotcms start"
  end
  action :nothing
end

service "dotcms" do
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

dotcms_version = node['prworld']['prworld_version']

yum_package "dotcms" do
  version dotcms_version
  action :install
  not_if { dotcms_version == '0.0.0-1' }
  notifies :restart, "service[dotcms]"
end

directory "/opt/dotCMS" do
  owner "tomcat"
  group "tomcat"
end

partportalplugin_version = node['applications']['cmsplugin']['partportalplugin_version']
yum_package "partportalplugin" do
  version partportalplugin_version
  action :install
  notifies :run, "execute[plugininstall]"
  not_if { node['applications']['cmsplugin']['partportalplugin_version'] == "0.0.0-1" }
end

yum_package "newsdateformat" do
  version node['prworld']['newsdateformat_version']
  action :install
  notifies :run, "execute[plugininstall]"
  not_if { node['prworld']['newsdateformat_version'] == "0.0.0-1" }
end

emailserver = data_bag_item("email", "#{node['emailservice']}")

template "/opt/dotCMS/dotserver/tomcat-8.0.18/webapps/ROOT/META-INF/context.xml" do
  source "prworld.context.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  variables(
    :mailserver => emailserver
  )
  notifies :restart, "service[dotcms]"
end

template "/opt/dotCMS/bin/startup.sh" do
  source "prworld-startup.sh.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0777"
  notifies :restart, "service[dotcms]"
end

template "/opt/dotCMS/dotserver/tomcat-8.0.18/bin/setenv.sh" do
  source "setenv.sh.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0755"
  #notifies :restart, "service[dotcms]"
end

#template "/opt/dotCMS/dotserver/tomcat-8.0.18/bin/dotStartup.sh" do
#  source "dotStartup.sh.erb"
#  owner  "tomcat"
#  group  "tomcat"
#  mode   "0777"
#  notifies :restart, "service[dotcms]"
#end

#template "/opt/dotCMS/dotserver/tomcat-8.0.18/conf/server.xml" do
#  source "dot-server.xml.erb"
#  owner  "tomcat"
#  group  "tomcat"
#  mode   "0644"
#  notifies :restart, "service[dotcms]"
#end

template "/opt/dotCMS/dotserver/tomcat-8.0.18/webapps/ROOT/WEB-INF/classes/ESAPI.properties" do
  source "ESAPI-8.properties.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  notifies :restart, "service[dotcms]"
end

template "/opt/dotCMS/dotserver/tomcat-8.0.18/webapps/ROOT/WEB-INF/classes/promethean.properties" do
  source "prworld.properties.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  #notifies :restart, "service[dotcms]"
end

#template "/opt/dotCMS/plugins/org.dotcms.tinymce_extended/conf/plugin.properties" do
#  source "tinymce.plugin.properties.erb"
#  owner  "tomcat"
#  group  "tomcat"
#  mode   "0644"
#  notifies :run, "execute[plugininstall]"
#end

if node["prworld"].attribute?("prworld_log_rotation") && node["prworld"]["prworld_log_rotation"] == "true"
  template "/etc/cron.daily/purge_prworld_logs" do
    source "dotcms-log-purge.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end
end

template "/etc/cron.daily/bundle_remove" do
  source "bundleremove.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

cron "bundle_remove" do
  command "find /opt/dotCMS/dotserver/tomcat-8.0.18/webapps/ROOT/assets/bundles/ -mtime +#{node['prworld']['bundleretain']} -exec rm -rf {} \\; > /var/log/prworld-bundle_remove.log 2>&1"
  minute "30"
  hour	 "2"
  action :create
end

cron "catalina_reset" do
  command "cat /dev/null > /opt/dotCMS/dotserver/tomcat-8.0.18/logs/catalina.out"
  minute  "1"
  hour    "0"
  action :create
end

cron "purgelogs" do
  command "find /opt/dotCMS/dotserver/tomcat-8.0.18/logs/ -mtime +10 -exec rm -rf {} \\; > /var/logs/purge_logs.log 2>&1"
  minute "10"
  hour   "0"
  action :create
end

if node['platform_version'].to_i == '7'
  template "/usr/local/bin/dotcms" do
    source "dotcms-init.erb"
    owner "root"
    group "root"
    mode "0755"
  end
  cookbook_file "/usr/lib/systemd/system/dotcms.service" do
    source "dotcms-service"
    owner "root"
    group "root"
    mode "0755"
  end
else
  template "/etc/init.d/dotcms" do
    source "dotcms-init.erb"
    manage_symlink_source	true
    owner  "root"
    group  "root"
    mode   "0755"
  end
end

replace_or_add "CONTENT_VERSION_HARD_LINK_promethean" do
  path "/opt/dotCMS/plugins/com.promethean.dotcms2/conf/dotmarketing-config.properties"
  pattern "CONTENT_VERSION_HARD_LINK"
  line "CONTENT_VERSION_HARD_LINK=false"
end

replace_or_add "CONTENT_VERSION_HARD_LINK_config" do
  path "/opt/dotCMS/plugins/com.dotcms.config/conf/dotmarketing-config.properties"
  pattern "CONTENT_VERSION_HARD_LINK"
  line "CONTENT_VERSION_HARD_LINK=false"
end

replace_or_add "CONTENT_VERSION_HARD_LINK_webapp" do
  path "/opt/dotCMS/dotserver/tomcat-8.0.18/webapps/ROOT/WEB-INF/classes/dotmarketing-config.properties"
  pattern "CONTENT_VERSION_HARD_LINK"
  line "CONTENT_VERSION_HARD_LINK=false"
end

service "dotcms" do
  supports :stop => true, :start => true, :restart => true, :status => true
  action [ :start,:enable ]
end

# Install Snapshots for backups
include_recipe "prworld::prworld-snap"
