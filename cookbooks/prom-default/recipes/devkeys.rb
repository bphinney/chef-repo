#
# Cookbook Name:: prom-default
# Recipe:: devkeys
#
# Copyright 2015, Promethean, Inc.
#
# All rights reserved - Do Not Redistribute
#

unless node.chef_environment == "local"
  directory "/home/tomcat/.ssh" do
    recursive true
    owner "tomcat"
    group "tomcat"
    mode  "0700"
  end

  jumpboxdata = data_bag_item("javadevs", "jumpbox")
  devkeys = []
  jumpboxdata.each do |user|
    authkey = user[1][1]
    unless authkey == 'u'
      devkeys << authkey
    end
  end

  template "/home/tomcat/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0600"
    variables( :devkeys => devkeys )
  end
  #Adding bash profile per IN-1195
  template "/home/tomcat/.bash_profile" do
    source "bash_profile.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0644"
  end
end
