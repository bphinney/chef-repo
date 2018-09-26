#
# Cookbook Name:: prom-classfront
# Recipe:: install-learner
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

learner_version = node['applications']['frontend']['learner_version']

#learner_version = node['applications']['learner_version']
directory "/opt/www/learner" do
  recursive true
  owner "apache"
  group "apache"
  action :create
end
yum_package "learner" do
  version learner_version
  action :install
  allow_downgrade true
  not_if { learner_version == '0.0.0-1' }
end

template "/etc/httpd/conf.d/learner.conf" do
  source "learner.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  variables( :countryblock => node['countryblock'].split(",") )
  action :delete
  notifies :run, "execute[configcheck]"
end
              
