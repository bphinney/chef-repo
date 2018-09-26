#
# Cookbook Name:: promethean
# Recipe:: dotcms
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'java::openjdk'
include_recipe 'prom-default'
include_recipe 'prom-default::repo'

# Create local hosts file entry for our own IP address
include_recipe 'prom-default::hostsfile'

# Newrelic attributes
if node.recipes.include?('newrelic')
  node.override['newrelic']['application_monitoring']['app_name'] = 'dotcms'
end

service 'dotcms' do
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

dotcms_version = node['dotcms']['dotcms_version']
yum_package 'dotcms' do
  version dotcms_version
  action :install
  allow_downgrade true
  not_if { dotcms_version == '0.0.0-1' }
  notifies :restart, 'service[dotcms]'
end

dotcmsplugin_version = node['applications']['cmsplugin']['dotcmsplugin_version']
yum_package 'dotcmsplugin' do
  version dotcmsplugin_version
  action :install
  allow_downgrade true
  not_if { dotcmsplugin_version == '0.0.0-1' }
end

directory '/opt/dotCMS' do
  owner 'tomcat'
  group 'tomcat'
end

template '/opt/dotCMS/dotserver/tomcat-7.0.54/webapps/ROOT/META-INF/context.xml' do
  source 'dotcms.context.xml.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0644'
  notifies :restart, 'service[dotcms]'
end

template '/opt/dotCMS/bin/startup.sh' do
  source 'dot-startup.sh.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0777'
  notifies :restart, 'service[dotcms]'
end

template '/opt/dotCMS/dotserver/tomcat-7.0.54/bin/setenv.sh' do
  source 'dot-setenv.sh'
  owner 'tomcat'
  group 'tomcat'
  mode '0644'
  notifies :restart, 'service[dotcms]'
end

template '/opt/dotCMS/dotserver/tomcat-7.0.54/bin/dotStartup.sh' do
  source 'dotStartup.sh.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0777'
  notifies :restart, 'service[dotcms]'
end

template '/opt/dotCMS/dotserver/tomcat-7.0.54/conf/server.xml' do
  source 'dot-server.xml.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0644'
  notifies :restart, 'service[dotcms]'
end

template '/opt/dotCMS/bin/system/src-conf/ESAPI.properties' do
  source 'ESAPI-7.properties.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0644'
end

template '/opt/dotCMS/dotserver/tomcat-7.0.54/webapps/ROOT/WEB-INF/classes/ESAPI.properties' do
  source 'ESAPI-7.properties.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0644'
  notifies :restart, 'service[dotcms]'
end

directory '/opt/dotCMS/dotserver/tomcat-7.0.54/webapps/ROOT/portal/pardot/' do
  recursive true
  action :create
  owner 'tomcat'
  group 'tomcat'
end

cookbook_file '/opt/dotCMS/dotserver/tomcat-7.0.54/webapps/ROOT/portal/pardot/ajax.jsp' do
  source 'ajax.jsp'
  mode '0644'
  owner 'tomcat'
  group 'tomcat'
end

if node['platform_version'].to_i == '7'
  template '/usr/local/bin/dotcms' do
    source 'dotcms-init.erb'
    manage_symlink_source true
    owner 'root'
    group 'root'
    mode '0755'
  end 
  template '/usr/lib/systemd/system/dotcms.service' do
    source 'dotcms-init-cent7.erb'
    owner 'tomcat'
    group 'tomcat'
    mode '0644'
  end 
  template '/etc/sysconfig/dotcms-init' do
    source 'dotcms-env-cent7.erb'
    owner 'tomcat'
    group 'tomcat'
    mode '0644'
  end 
else
  template '/etc/init.d/dotcms' do
    source 'dotcms-init.erb'
    manage_symlink_source true
    owner 'root'
    group 'root'
    mode '0755'
  end
end


template '/usr/local/sbin/dotcmsplugin_deploy.sh' do
  source 'dotcmsplugin_deploy.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end
 if node['dotcms'].attribute?('dotcms_log_rotation') && node['dotcms']['dotcms_log_rotation'] == 'true'
  template "/etc/cron.daily/dotcms-log-purge" do
    source "dotcms-log-purge.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end
end

execute 'cmsplugin-install' do
  command '/usr/local/sbin/dotcmsplugin_deploy.sh'
  action :run
  only_if 'test -d /opt/storage/com.promethean.dotcms'
end

include_recipe "dotcms::dotcms-snap"
