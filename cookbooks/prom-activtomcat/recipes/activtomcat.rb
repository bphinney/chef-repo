#
# Cookbook Name:: prom-activtomcat
# Recipe:: activtomcat
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "java::openjdk"
include_recipe "prom-default::repo"
include_recipe "prom-default::selinux"
include_recipe "prom-activtomcat::cacert"

package "activtomcat" do
  action :install
  version node['tomcat']['version']
end

include_recipe "prom-activtomcat::usermanagement"

%w{webapps logs temp work lib conf bin}.each do |dir|
  directory "/opt/tomcat/#{dir}" do
    owner "tomcat"
    group "tomcat"
    action :create
  end
end

directory "/var/run/tomcat" do
  owner  "tomcat"
  group  "tomcat"
  action :create
end

directory "/opt/storage" do
  owner  "root"
  group  "root"
  action :create
end

service "activtomcat" do
  if node['platform_version'].to_i == '7'
    start_command "/opt/tomcat/bin/activtomcat start"
    stop_command "/opt/tomcat/bin/activtomcat stop"
    restart_command "/opt/tomcat/bin/activtomcat restart"
    status_command "/opt/tomcat/bin/activtomcat status"
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :enable => true
  action :nothing
end

if node.recipes.include?('prom-activfoundation::activfoundation')
  afrecipe = "true"
else
  afrecipe = "false"
end

template "/opt/tomcat/conf/server.xml" do
  source "server8.xml.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
  variables(
    :afrecipe => afrecipe
  )
  notifies :restart, "service[activtomcat]"
end

template "/opt/tomcat/conf/context.xml" do
  source "context.xml.erb"
  owner  "tomcat"
 group  "tomcat"
  mode   "0644"
  notifies :restart, "service[activtomcat]"
end

#template "/opt/tomcat/conf/logback.xml" do
#  source "activfoundation.logback.xml.erb"
#  owner  "tomcat"
#  group  "tomcat"
#  mode   "0644"
#  if node['tomcat']['logback'] == "false"
#    action :delete
#  end
#end

# adding base options for cent7 java using systemd layout
if node['platform_version'].to_i == '7' 
  template '/etc/sysconfig/activtomcat-settings' do
    source 'activtomcat_cent7_java.erb'
    owner 'tomcat'
    group 'tomcat'
    mode '0644'
  end 
  cookbook_file '/usr/lib/systemd/system/activtomcat.service' do
    source 'activtomcat-init-cent7'
    owner 'root'
    group 'root'
    mode '755'
  end 
end

# needed for both cent7 and cent6
template '/opt/tomcat/bin/activtomcat' do
  source 'activtomcat-init.erb'
  owner 'tomcat'
  group 'tomcat'
  mode '0755'
end 

%w{web.xml tomcat-users.xml logging.properties catalina.properties catalina.policy}.each do |file|
  execute "chown_#{file}" do
    command "chown tomcat:tomcat /opt/tomcat/conf/#{file}"
    action :run
    not_if %Q{stat -c %U /opt/tomcat/conf/"#{file}" | grep 'tomcat'}
    notifies :restart, "service[activtomcat]"
  end
end

unless node['tomcat']['jarstoskip'].nil? || node['tomcat']['jarstoskip'].empty?
  replace_or_add "jarsToSkip" do
    path "/opt/tomcat/conf/catalina.properties"
    pattern "tomcat.util.scan.StandardJarScanFilter.jarsToSkip=*"
    line "tomcat.util.scan.StandardJarScanFilter.jarsToSkip=#{node['tomcat']['jarstoskip']}"
  end
end

unless node['tomcat']['Tldjarstoskip'].nil? || node['tomcat']['Tldjarstoskip'].empty?
  replace_or_add "TldjarsToSkip" do
    path "/opt/tomcat/conf/catalina.properties"
    pattern "tomcat.util.scan.StandardJarScanFilter.jarsToScan=*"
    line "#tomcat.util.scan.StandardJarScanFilter.jarsToScan="
  end
end

template "/etc/cron.daily/activtomcat-log" do
  source "activtomcat_log_clear.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/etc/cron.daily/activtomcat-log" do
  source "activtomcat_log_clear.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

# Section for Winblows Cert for LDAP support
template "/etc/java/security/wb2.crt" do
  source "wb2.crt.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  only_if { node["java"]["truststore"] == "true" }
end

execute "wb2-truststore-create" do
  command "[[ `keytool -list -keystore /etc/pki/java/cacerts -alias wb2 -storepass changeit -noprompt | grep -o SHA1` == 'SHA1' ]] || { keytool -import -alias wb2 -file /etc/java/security/wb2.crt -keystore /etc/pki/java/cacerts -storepass changeit -noprompt; }"
  only_if { node["java"]["truststore"] == "true" } 
  not_if { "keytool -list -keystore /etc/pki/java/cacerts -alias wb2 -storepass changeit" }
  action :run
end

execute "wb2-truststore-remove" do
  command "if [[ `keytool -list -keystore /etc/pki/java/cacerts -alias wb2 -storepass changeit -noprompt | grep -o SHA1` == 'SHA1' ]]; then rm -f /etc/java/security/wb2.crt; keytool -delete -alias wb2 -keystore /etc/pki/java/cacerts -storepass changeit -noprompt; fi"
  only_if { node["java"]["truststore"] == "false" }
  only_if "keytool -list -keystore /etc/pki/java/cacerts -alias wb2 -storepass changeit"
  action :run
end
# End Section for Winblows Cert.

if node['java']['jmx_console_enable'] == "true" 
  template "/opt/tomcat/conf/jmxremote.access" do
    source "jmxremote.access.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0600"
    notifies :restart, "service[activtomcat]"
  end
  template "/opt/tomcat/conf/jmxremote.password" do
    source "jmxremote.password.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0600"
    notifies :restart, "service[activtomcat]"
  end
end

template "/opt/tomcat/bin/setenv.sh" do
  source "setenv.sh.erb"
  owner  "tomcat"
  group  "tomcat"
  mode   "0755"
  notifies :restart, "service[activtomcat]"
end

template "/etc/logrotate.d/tomcat" do
  source "logrotate-tomcat.erb"
  owner "root"
  group "root"
  mode  "0644"
end

if node.attribute?('collectd') && node['collectd']['client_active'] == "true"
  include_recipe "prom-collectd"
end
