#
# Cookbook Name:: promethean
# Recipe:: lowerenvaudit
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

template "/usr/local/bin/audit_ip" do
  source "audit_ip.erb"
  owner  "root"
  owner  "root"
  mode   "0750"
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
  weekday "0"
end
