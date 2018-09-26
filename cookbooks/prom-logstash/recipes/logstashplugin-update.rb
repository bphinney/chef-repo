#
# Cookbook Name:: logstash
# Recipe:: logstashplugin-update
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

logstashplugins = "#{node['logstash']['plugins']}"
logstashplugins.split(" ").each do |plugin|
  execute "logstash-plugin-update" do
    command "/opt/logstash/bin/plugin update #{plugin}"
    action :run
  end
end
