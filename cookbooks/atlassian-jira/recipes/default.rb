#
# Cookbook Name:: atlassian-jira
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

# Add storage for atlassian jira backup
aws = data_bag_item("aws-sdk", "main")
include_recipe "promaws"
if node['provider'] == "aws"
  # Install Snapshots for backups
  promaws_ebssnap "atlassian" do
    frequency "daily"
    retention 7
    action :enable
    only_if { "#{node["provider"]}" == "aws" }
  end
end

%w{ httpd MySQL-client }.each do |pkg|
  package pkg do
    action :upgrade
  end
end

file "/etc/httpd/conf.d/README" do
  action :delete
  only_if "test -f /etc/httpd/conf.d/README"
end

template "/etc/init.d/jira" do
  source "jira-init.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

service "jira" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

service "httpd" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action :nothing
end

remote_file "/opt/jira/lib/#{node['mysqlconnector']}" do
  source "http://yumrepo.prometheanjira.com/core/#{node['mysqlconnector']}"
  mode  "0644"
  owner "jira"
  group "jira"
  action :create_if_missing
end

node['oldmysqlconnector'].each do |mysql|
  file "/opt/jira/lib/#{mysql}" do
    action :delete
    only_if "test -f /opt/jira/lib/#{mysql}"
    notifies :restart, "service[jira]"
  end
end

execute "cfg-xml-backup" do
  command 'mv /opt/jira-data/dbconfig.xml.bak /opt/jira-data/dbconfig.xml.bak-`date +%s`; cp -a /opt/jira-data/dbconfig.xml /opt/jira-data/dbconfig.xml.bak'
  only_if '[[ `diff -qN /opt/jira-data/dbconfig.xml /opt/jira-data/dbconfig.xml.bak` ]]'
  action :run
end

execute "server-xml-backup" do
  command 'mv /opt/jira/conf/server.xml.bak /opt/jira/conf/server.xml.bak-`date +%s`; cp -a /opt/jira/conf/server.xml /opt/jira/conf/server.xml.bak'
  only_if '[[ `diff -qN /opt/jira/conf/server.xml /opt/jira/conf/server.xml.bak` ]]'
  action :run
end

template "/opt/jira-data/dbconfig.xml" do
  source "jira.cfg.xml.erb"
  owner  "jira"
  group  "jira"
  mode   "0644"
  notifies :restart, "service[jira]"
end

template "/etc/sysconfig/httpd" do
  source "sysconfig-httpd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/etc/httpd/conf.d/jira.conf" do
  source "httpd_rewrite.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(:appname => "jira",
            :sslRedirect => "true"
           )
  notifies :restart, "service[httpd]"
end

template "/etc/httpd/conf.d/block.load" do
  source "block.load.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[httpd]"
end

template "/opt/jira/bin/check-java.sh" do
  source "check-java.sh.erb"
  owner  "jira"
  group  "jira"
  mode   "0755"
end

mail = node["emailservice"]
begin
  mailserver = data_bag_item("email", mail)
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{mail}")
end
template "/opt/jira/conf/server.xml" do
  source "jira-server.xml.erb"
  owner  "jira"
  group  "jira"
  mode   "0644"
  variables(
    :emailserver => mailserver["smtpserver"],
    :emailuser => mailserver["smtpuser"],
    :emailpass => mailserver["smtppass"]
  )
  notifies :restart, "service[jira]"
end

template "/opt/jira/bin/setenv.sh" do
  source "jira.setenv.sh.erb"
  owner  "jira"
  group  "jira"
  mode   "0755"
  notifies :restart, "service[jira]"
end

cron "atlassian-backup" do
  command "# /usr/local/sbin/atlassian-backup > /usr/local/sbin/atlassian-backup.log"
  minute  "05"
  hour    "1"
  action :delete
end

cron "jira-restart" do
  command "/sbin/service jira restart"
  minute "10"
  hour   "1"
  weekday "0"
end

service "jira" do
  supports :start => true, :stop => true, :restart => true, :status => true
  action [:enable,:start]
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

#Changes for email templates
%w{filtersubscription.vm issuecommented.vm issuementioned.vm issueresolved.vm issueworklogupdated.vm issueassigned.vm issuecreated.vm issuemoved.vm issueupdated.vm issueworkstarted.vm issueclosed.vm issuedeleted.vm issuenotify.vm issueworklogdeleted.vm  issueworkstopped.vm issuecommentedited.vm issuegenericevent.vm issuereopened.vm issueworklogged.vm}.each do |template|
  replace_or_add "#{template}_1" do
    path "/opt/jira/atlassian-jira/WEB-INF/classes/templates/email/subject/#{template}"
    pattern "${issue.getPriorityObject().getNameTranslation($i18n)}"
    line "${issue.getPriorityObject().getNameTranslation($i18n)}"
    not_if "grep '${issue.getPriorityObject().getNameTranslation($i18n)}' /opt/jira/atlassian-jira/WEB-INF/classes/templates/email/subject/#{template}"
  end
  replace_or_add "#{template}_2" do
    path "/opt/jira/atlassian-jira/WEB-INF/classes/templates/email/subject/#{template}"
    pattern "($issue.key) $issue.summary"
    line "($issue.key) $issue.summary"
    not_if "grep '($issue.key) $issue.summary' /opt/jira/atlassian-jira/WEB-INF/classes/templates/email/subject/#{template}"
  end
end

directory "/opt/jira/scripts" do
  recursive true
end

template "/opt/jira/scripts/labelmanager.groovy" do
  source "labelmanager.erb"
  owner  "jira"
  group  "jira"
  mode   "0644"
end

template "/opt/jira/atlassian-jira/robots.txt" do
  source "robots.txt.erb"
  owner  "jira"
  group  "jira"
  mode   "0644"
end
