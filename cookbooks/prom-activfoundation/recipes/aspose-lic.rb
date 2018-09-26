#
# Cookbook Name:: prom-activfoundation
# Recipe:: aspose-lic
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#


cookbook_file "/opt/tomcat/conf/Aspose.Total.Product.Family.lic" do
  source "Aspose.Total.Product.Family.lic"
  owner  "tomcat"
  group  "tomcat"
  mode   "0644"
end

yum_package "msttcorefonts" do
  action :upgrade
  only_if { node.chef_environment == "dev2" }
end
