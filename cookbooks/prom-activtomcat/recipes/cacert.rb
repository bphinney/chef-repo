#
# Cookbook Name:: prom-activtomcat
# Recipe:: cacert
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

execute "cacert-fix" do
  command "mv /etc/pki/java/cacerts.rpmnew /etc/pki/java/cacerts"
  only_if { File.exists?("/etc/pki/java/cacerts.rpmnew") }
end
