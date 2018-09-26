#
# Cookbook Name:: prom-rabbitmq
# Recipe:: rabbitmq-clean
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

%w{3.3.4-1 3.3.5-1 3.4.4-1 3.5.4-1 3.5.6-1}.each do |rabbitversion|
  file "/var/chef/cache/rabbitmq-server-#{rabbitversion}" do
    action :delete
  end
end

