#
# Cookbook Name:: prom-rabbitmq
# Recipe:: rabbitmq-admin
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

#rabbitmq_user "bugsbunny" do
#  tag "administrator"
#  action :set_tags
#end

# Install the rabbit-mq admin cli tool
remote_file '/usr/local/bin/rabbitmqadmin' do
  source 'http://localhost:15672/cli/rabbitmqadmin'
  mode '0755'
  action :create
  ignore_failure true
end

