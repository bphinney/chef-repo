#
# Cookbook Name:: prom-activtomcat
# Recipe:: usermanagement 
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

execute "tomcat-change" do
  command "if [ -d /opt/tomcat ]; then chown -R tomcat:tomcat /opt/tomcat; fi; if [ -d /opt/screenservice ]; then chown -R tomcat:tomcat /opt/screenservice; fi; if [ -d /opt/vertx ]; then chown -R tomcat:tomcat /opt/vertx; fi"
  only_if { node.chef_environment.include?("local") }
  action :nothing
end

####################################################################
# FOR LOCAL/SOLO INSTALLATIONS
# This is where the rtkit user is installed
if node.chef_environment.include?("local") && node['etc']['group']['rtkit']
  expected_rtkit_gid = "492"
  expected_tomcat_gid = "496"
  current_rtkit_gid = %x(id -g rtkit).strip!
  current_tomcat_gid = %x(id -g tomcat).strip!

  if (current_rtkit_gid != expected_rtkit_gid and current_tomcat_gid != expected_tomcat_gid)
    puts "rtkit: does not match #{expected_rtkit_gid} and tomcat: doest not match #{expected_tomcat_gid}"
    puts "Changing rtkit and tomcat GIDs"
      result = %x(groupmod --gid 10#{expected_rtkit_gid} rtkit && \
        usermod --gid 10#{expected_rtkit_gid} rtkit 2>/dev/null)
      result = %x(groupmod --gid #{expected_tomcat_gid} tomcat && \
        usermod --gid #{expected_tomcat_gid} tomcat 2>/dev/null)
      result = %x(groupmod --gid #{expected_rtkit_gid} rtkit && \
        usermod --gid #{expected_rtkit_gid} rtkit 2>/dev/null)
  elsif (current_rtkit_gid != expected_rtkit_gid and current_tomcat_gid == expected_tomcat_gid)
    puts "rtkit: does not match #{expected_rtkit_gid} but tomcat: does match #{expected_tomcat_gid}"
    puts "Changing rtkit gid"
      %x(groupmod --gid #{expected_rtkit_gid} rtkit && \
        usermod --gid #{expected_rtkit_gid} rtkit 2>/dev/null)
  elsif (current_rtkit_gid == expected_rtkit_gid and current_tomcat_gid != expected_tomcat_gid)
    puts "rtkit: does  match #{expected_rtkit_gid} but tomcat: does not match #{expected_tomcat_gid}"
    puts "Changing tomcat gid"
      %x(groupmod --gid #{expected_tomcat_gid} tomcat && \
        usermod --gid #{expected_tomcat_gid} tomcat 2>/dev/null)
  end
end
####################################################################
# TOMCAT APPLICATION USER SECTION
# check to see if the tomcat user attributes are set. If they are not, exit gracefully.  We can not proceede if there are no
# attributes defined. 
Chef::Log.info("Usermanagement running")
return if (node['java']['user_name'].nil? || node['java']['user_gid'].nil? || node['java']['user_uid'].nil? rescue false)

  group "rtkit" do
    gid "492"
    action :modify
    only_if { node['etc']['group']['rtkit'] }
  end

  user "rtkit" do
    gid "rtkit"
    action :modify
    only_if { node['etc']['passwd']['rtkit'] }
  end

  # First we have to create the user's group using chef controls
  group node['java']['user_name'] do
    gid node['java']['user_gid']
    action :create
    notifies :run, "execute[tomcat-change]"
    not_if { node['etc']['group']['tomcat'] }
  end

  # Now we add the user using chef controls
  user node['java']['user_name'] do
    comment "Tomcat User"
    uid node['java']['user_uid']
    gid node['java']['user_name']
    home "/home/#{node['java']['user_name']}"
    shell "/bin/bash"
    not_if { node['etc']['passwd']['tomcat'] }
    action :create
    notifies :run, "execute[tomcat-change]"
  end
