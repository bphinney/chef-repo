#
# Cookbook Name:: prom-newrelic
# Recipe:: default
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

node.default['newrelic']['java-agent'].delete(:execute_install) rescue nil
