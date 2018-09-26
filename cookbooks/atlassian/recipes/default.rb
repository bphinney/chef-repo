#
# Cookbook Name:: atlassian
# Recipe:: default
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#


include_recipe "atlassian::hostsfile"
include_recipe "prom-default::repo"
include_recipe "prom-default"
