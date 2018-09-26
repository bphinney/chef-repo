#
# Cookbook Name:: prom-chef
# Recipe:: jumpbox
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"
include_recipe "promaws"
include_recipe "prom-default::hostsfile_update"

%w{git redis MySQL-client scriptella screen java-1.8.0-openjdk}.each do |package|
  package package do
    action :upgrade
  end
end

include_recipe "prom-chef::hardening"
include_recipe "prom-chef::jumpbox-data"
