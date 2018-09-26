
# Cookbook Name:: prom-elasticsearch
# Recipe:: elasticsearchinit
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "yum::default"
include_recipe "java::openjdk"

yum_package "patch" do
  action :install
  allow_downgrade true
end
