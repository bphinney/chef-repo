#
# Cookbook Name:: prom-default
# Recipe:: chefclient-clean
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Cleans extra chef-client binaries from chef cache directory
#

%w{12.8.1-1.el6 12.9.38-1.el6 12.9.41-1.el6 12.10.24-1.el6 12.11.18-1.el6}.each do |chefclient|
  file "/var/chef/cache/omnibus_updater/chef-#{chefclient}.x86_64.rpm" do
    action :delete
  end
end

