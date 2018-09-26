#
# Cookbook Name:: prom-chef
# Recipe:: chef-api-gem.rb
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

if node.environment == "prod" or node.environment == "staging"
# Removes chef-api and installs patched chefgem-chef-api (IN-1031)
if node['chef_api']['chef_api_patch'] == true
  chef_gem 'chef-api' do
    compile_time false
    action :remove
    only_if { system('/opt/chef/embedded/bin/gem list | grep "chef-api (0.5.0)"') }
  end
  execute 'chefgem-chef-api' do
    command 'yum install -y chefgem-chef-api'
    action :run
    not_if { system('/opt/chef/embedded/bin/gem list | grep "chef-api (0.5.1)"') }
    not_if "rpm -qa | grep chefgem-chef-api"
  end
else
  execute 'chefgem-chef-api' do
    command 'yum remove -y chefgem-chef-api'
    action :run
    only_if { system('/opt/chef/embedded/bin/gem list | grep "chef-api (0.5.1)"') }
    only_if "rpm -qa | grep chefgem-chef-api"
  end
  chef_gem 'chef-api' do
    compile_time false
    action :install
    not_if { system('/opt/chef/embedded/bin/gem list | grep "chef-api (0.5.0)"') }
  end
end
end
