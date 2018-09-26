#
# Cookbook Name:: prom-activfoundation
# Recipe:: gfcontent-update 
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute

cookbook_file "/opt/tomcat/content/global/2c9fb/2c9fb25b4395c6290143961e05e20145.png" do
  source "2c9fb25b4395c6290143961e05e20145.png"
  owner  "tomcat"
  group  "tomcat"
  not_if { File.exist?("/opt/tomcat/content/global/2c9fb/2c9fb25b4395c6290143961e05e20145.png") }
end
