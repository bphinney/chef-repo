#
# Cookbook Name:: prom-activfoundation
# Recipe:: activfoundation-saml
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
if node["java"]["samlkeystore"] == "true" 
  directory "/opt/tomcat/security" do
    owner "tomcat"
    group "tomcat"
  end
  cookbook_file "/opt/tomcat/security/samlKeystore.jks" do
    source "af#{node.chef_environment}.keystore"
    owner  "tomcat"
    group  "tomcat"
    mode   "0644"
  end
end
