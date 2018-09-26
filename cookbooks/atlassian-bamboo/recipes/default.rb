#
# Cookbook Name:: atlassian-bamboo
# Recipe:: default
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'atlassian::hostsfile'
include_recipe 'atlassian::selinux'
include_recipe 'java::openjdk'

include_recipe 'prom-default'
include_recipe 'prom-presearch'

include_recipe 'atlassian-bamboo::build'

# Add storage for stash backup
aws = data_bag_item('aws-sdk', 'main')
include_recipe 'promaws'
if node['provider'] == 'aws'
  # Install Snapshots for backups
  promaws_ebssnap 'bamboo' do
    frequency 'weekly'
    retention 2
    action :enable
    only_if { "#{node["provider"]}" == "aws" }
  end 
end

%w{httpd rpm-build zip}.each do |package|
  package package do
    action :upgrade
  end
end

service 'bamboo' do
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

service 'httpd' do
  supports :stop => true, :start => true, :restart => true, :status => true
  action :nothing
end

%w{/opt/bamboo-data /opt/bamboo-data/.ssh /opt/npm-temp /opt/bamboo-data/backups}.each do |dir|
  directory dir do
    owner 'bamboo'
    group 'bamboo'
    action :create
  end
end

execute 'server-xml-backup' do
  command 'mv /opt/bamboo/conf/server.xml.bak /opt/bamboo-data/backups/server.xml.bak-`date +%s`; cp -a /opt/bamboo/conf/server.xml /opt/bamboo/conf/server.xml.bak'
  only_if '[[ `diff -qN /opt/bamboo/conf/server.xml /opt/bamboo/conf/server.xml.bak` ]]'
  action :run
end

execute 'cfg-xml-backup' do
  command 'mv /opt/bamboo-data/bamboo.cfg.xml.bak /opt/bamboo-data/backups/bamboo.cfg.xml.bak-`date +%s`; cp -a /opt/bamboo-data/bamboo.cfg.xml /opt/bamboo-data/bamboo.cfg.xml.bak'
  only_if '[[ `diff -qN /opt/bamboo-data/bamboo.cfg.xml /opt/bamboo-data/bamboo.cfg.xml.bak` ]]'
  action :run
end

template '/opt/bamboo-data/bamboo.cfg.xml' do
  source 'bamboo.cfg.xml.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0644'
  notifies :restart, 'service[bamboo]'
end

template '/usr/local/sbin/npm-install' do
  source 'npm-install.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
end

#Populate servers for distribute template
backendmajor=[]
$presearch_node['backendmajor_nodes'].each do |server|
  backendmajor << server['ipaddress']
end
backendmajor = backendmajor.sort.join(' ')
frontendmajor=[]
$presearch_node['frontendmajor_nodes'].each do |server|
  frontendmajor << server['ipaddress']
end
frontendmajor = frontendmajor.sort.join(' ')
backendminor=[]
$presearch_node['backendminor_nodes'].each do |server|
  backendminor << server['ipaddress']
end
backendminor = backendminor.sort.join(' ')
frontendminor=[]
$presearch_node['frontendminor_nodes'].each do |server|
  frontendminor << server['ipaddress']
end
frontendminor = frontendminor.sort.join(' ')

template '/usr/local/bin/distribute' do
  source 'distribute.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
  variables(
    backendmajor:  backendmajor, 
    frontendmajor: frontendmajor, 
    backendminor:  backendminor, 
    frontendminor: frontendminor
  )
end

remote_file "/opt/bamboo/atlassian-bamboo/WEB-INF/lib/#{node['mysqlconnector']}" do
  source "http://yumrepo.prometheanjira.com/core/#{node['mysqlconnector']}"
  mode  '0644'
  owner 'bamboo'
  group 'bamboo'
  action :create_if_missing
end

node['oldmysqlconnector'].each do |mysql|
  file "/opt/bamboo/atlassian-bamboo/WEB-INF/lib/#{mysql}" do
    action :delete
    only_if "test -f /opt/bamboo/atlassian-bamboo/WEB-INF/lib/#{mysql}"
    notifies :restart, 'service[bamboo]'
  end
end

template '/etc/init.d/bamboo' do
  source 'bamboo-init.erb'
  owner  'root'
  group  'root'
  mode   '0755'
end

template '/etc/sysconfig/httpd' do
  source 'sysconfig-httpd.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  notifies :restart, 'service[httpd]'
end

template '/etc/httpd/conf.d/bamboo.conf' do
  source 'httpd_rewrite.conf.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables( 
    appname:     'bamboo',
    sslRedirect: 'true'
  )
  notifies :restart, 'service[httpd]'
end

template '/opt/bamboo/atlassian-bamboo/WEB-INF/classes/log4j.properties' do
  source 'log4j.properties.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0644'
end

# Delete Unnecessary Files

file '/etc/httpd/conf.d/welcome.conf' do
  action :delete
  only_if { File.exists?('/etc/httpd/conf.d/welcome.conf') }
end

file "/etc/httpd/conf.d/README" do
  action :delete
  only_if "test -f /etc/httpd/conf.d/README"
end

# End delete unnecessary files

mail = node['emailservice']
begin
  mailserver = data_bag_item('email', mail)
rescue Net::HTTPServerException
  Chef::Log.info("No email information found in data bag item #{mail}")
end

template '/opt/bamboo/conf/server.xml' do
  source 'bamboo-server.xml.erb'
  owner  'bamboo'
  group  'bamboo'
  variables(
    emailserver: mailserver['smtpserver'],
    emailuser:   mailserver['smtpuser'],
    emailpass:   mailserver['smtppass']
  )
  notifies :restart, 'service[bamboo]'
end

template '/opt/bamboo/bin/setenv.sh' do
  source 'bamboo.setenv.sh.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0755'
  notifies :restart, 'service[bamboo]'
end

#execute "artifactory-remove" do
#  command "rm -rf /opt/bamboo/atlassian-bamboo/WEB-INF/lib/bamboo-artifactory-plugin-#{node['bamboo_artifactory_old']}.jar"
#  only_if {File.exists?("/opt/bamboo/atlassian-bamboo/WEB-INF/lib/bamboo-artifactory-plugin-#{node['bamboo_artifactory_old']}.jar")}
#  action :nothing
#end

#artifactory_plugin = "bamboo-artifactory-plugin-#{node['bamboo_artifactory_version']}.jar"
#execute artifactory_plugin do
#  command "cp /root/plugin/#{artifactory_plugin} /opt/bamboo/atlassian-bamboo/WEB-INF/lib/#{artifactory_plugin}; chown bamboo.bamboo /opt/bamboo/atlassian-bamboo/WEB-INF/lib/#{artifactory_plugin}"
#  not_if {File.exists?("/opt/bamboo/atlassian-bamboo/WEB-INF/lib/#{artifactory_plugin}") || node['bamboo_artifactory'] == "false"}
#  notifies :run, "execute[artifactory-remove]"
#end

service 'bamboo' do
  action [:enable, :start]
end

service 'httpd' do
  action [:enable, :start]
end

hostsfile_entry node['ipaddress'] do
  hostname node['hostname']
  comment 'Updated by Chef'
  action :create
  unique true
end

hostsfile_entry '10.0.1.109' do
  hostname 'stashdirect.prometheanjira.com'
  comment 'Local hostsfile entry for Application links'
  action :create
  unique true
end

hostsfile_entry '10.0.1.132' do
  hostname 'atlassian wikidirect.prometheanjira.com jiradirect.prometheanjira.com'
  comment 'Local hostsfile entry for Application links'
  action :create
  unique true
end

template '/opt/bamboo/atlassian-bamboo/robots.txt' do
  source 'robots.txt.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0644'
end

template '/opt/bamboo-data/.npmrc' do
  source 'npmrc.erb'
  owner  'bamboo'
  group  'bamboo'
  mode   '0600'
end

cron 'tmp-clean' do
  command '/bin/rm -rf /opt/npm-temp/npm-* > /var/log/tmp-clean.log 2>&1'
  minute '20'
  hour   '4'
  action :create
end

execute 'gitrelocate' do
  command 'mv /usr/bin/git /usr/bin/git_bak && ln -s /opt/bamboo-data/executable/git/bin/git /usr/bin/git'
  not_if {File.exists?('/usr/bin/git_bak')}
  action :run
end

