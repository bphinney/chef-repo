#
# Cookbook Name:: prom-chef
# Recipe:: chefserver
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"
include_recipe "promaws"
include_recipe "prom-default::hostsfile_update"

# We need these gems for scripts, tools and such
# This clause installs gems using the chef gem 
# as opposed to the system gem
%w{ cloudflare colorize json logger mysql2 sinatra terminal-table timeout tty-prompt vine }.each do |gem|
  chef_gem gem do
    action :install
  end
end


template "/usr/bin/daemon-check" do
  source "daemon-check.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/usr/bin/remote-update" do
  source "remote-update.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/usr/bin/hostsfile-update" do
  source "hostsfile-update.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/etc/motd" do
  source "motd.erb"
  owner  "root"
  group  "root"
  mode   "0644"
end

if node['provider'] == "aws"
  include_recipe "promaws::default"
  aws = data_bag_item("aws-sdk", "main")
  # EC2 Production and RDS Security Group Managmenent
  template "/usr/bin/aws_env_secure.rb" do
    source "aws_env_secure.rb.erb"
    owner  "root"
    group  "root"
    mode   "0750"
    variables(
      :access_key_id     => aws['aws_access_key_id'],
      :secret_access_key => aws['aws_secret_access_key'],
      :env_secgroup      => node["env_secgroup"],
      :env_secrds        => node["env_secrds"]
      )
  end
end

template "/usr/local/bin/chef-user-create" do
  source "chef-server-user-create.erb"
  owner  "root"
  group  "root"
  mode   "0750"
end

template "/usr/local/bin/chef-user-delete" do
  source "chef-server-user-delete.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/usr/local/bin/email-release" do
  source "email-release.erb"
  owner  "root"
  group  "root"
  mode   "0750"
end

template "/usr/local/bin/apache_whitelist.rb" do
  source "apache_whitelist.rb.erb"
  owner  "root"
  owner  "root"
  mode   "0750"
    variables(
      :htaccessurl => "#{node["env_htaccessurl"]}" == '' ? 'Lower+Environment+Access+-+Classflow Production+Support+-+Classflow Development+Support+-+Classflow' : "#{node["env_htaccessurl"]}"
    )
end

template "/usr/local/bin/apache_blacklist.rb" do
  source "apache_blacklist.rb.erb"
  owner  "root"
  owner  "root"
  mode   "0750"
end

cron "process_apache_whitelist" do
  command "/usr/local/bin/apache_whitelist.rb > /dev/null 2>&1"
  minute  "*/30"
  hour    "*"
end

# Script for chefrepo update, pulls cookbook updates and uploads them
template "/usr/bin/chefrepo-update" do
  source "chefrepo-update.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "/usr/local/bin/lowerenv_audit.sh" do
  source "lowerenv_audit.sh.erb"
  owner  "root"
  owner  "root"
  mode   "0750"
end

cron "audit_lower_envs" do
  command "/usr/local/bin/lowerenv_audit.sh > /dev/null 2>&1"
  minute  "1"
  hour    "1"
  only_if { node['chef_server']['audit'] == "enable" }
end

cron "aws_env_secure" do
  command "/usr/bin/aws_env_secure.rb > /var/log/aws_env_secure.log 2>&1 || cat /var/log/aws_env_secure.log"
  minute "*/30"
  hour   "*"
  mailto "devops@prometheanproduct.com"
  if node['provider'] == "aws"
    action :create
  else
    action :delete
  end
end

# Aws IP Whitelisting for Vagrant Image Downloads
if node['provider'] == "aws"
  template "/usr/local/bin/vagrant_whitelist.rb" do
    source "vagrant_whitelist.rb.erb"
    owner  "root"
    owner  "root"
    mode   "0750"
    variables(
      :access_key_id     => aws["aws_access_key_id"],
      :secret_access_key => aws["aws_secret_access_key"]
      )
    if node["vagrant"].attribute?("whitelist") && node["vagrant"]["whitelist"] == "true"
      action :create
    else
      action :delete
    end
  end

  cron "process_vagrant_whitelist" do
    command "/usr/local/bin/vagrant_whitelist.rb > /dev/null 2>&1"
    minute  "20"
    hour    "*"
    if node["vagrant"].attribute?("whitelist") && node["vagrant"]["whitelist"] == "true"
      action :create
    else
      action :delete
    end
  end
end

# Periodically update data bag tenants through chef-tenant-update
cron "chef-tenant-update" do
  command "/usr/bin/chef-client -o prom-chef::chef_tenant_update > /dev/null 2>&1"
  minute "40"
  hour   "*"
  action :create
end


include_recipe "prom-chef::chefserver-snap"

include_recipe "prom-chef::hardening"
