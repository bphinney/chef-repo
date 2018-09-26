#
# Cookbook Name:: prom-mailrelay
# Recipe:: mailrelay
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#
# This recipe configures postfix to relay mail through another MTA.  Requires a mailservice with permisson to route mail out

include_recipe "prom-mailrelay::default"

node.default['postfix']['myhostname'] = node['hostname']
unless node['domain'].nil? || node['domain'].empty?
  node.default['postfix']['mydomain'] = node['domain']
else
  node.default['postfix']['mydomain'] = "prometheanjira.com"
end

service "postfix" do
  supports :restart => true, :reload => true, :start => true, :stop => true
  action :nothing
end

execute "postmap" do
  command "postmap /etc/postfix/sasl_passwd"
  action :nothing
end

begin
  mailserver = data_bag_item("email", "#{node['emailservice']}")
    rescue Net::HTTPServerException
      Chef::Log.info("No email information found in data bag item #{node['emailservice']}")
end

template "/etc/postfix/main.cf" do
  source "postfix_main.cf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables(
    :smtpserver => "#{mailserver['smtpserver']}:587",
    :smtpuser => mailserver['smtpuser'],
    :smtppass => mailserver['smtppass']
  )
  notifies :restart, "service[postfix]"
end

template "/etc/postfix/sasl_passwd" do
  source "sasl_passwd.erb"
  owner  "root"
  group  "root"
  mode   "0600"
  variables(
    :smtpserver => "#{mailserver['smtpserver']}:587",
    :smtpuser => mailserver['smtpuser'],
    :smtppass => mailserver['smtppass']
  )
  notifies :run, "execute[postmap]"
end

                                                                
