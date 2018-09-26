#
# Cookbook Name:: android_ota
# Recipe:: default
#
# Copyright 2016, Promethean, Inc
#
# All rights reserved - Do Not Redistribute
#
# Initial installations for ota updater 
#

# Install aws snapshot backups
promaws_ebssnap 'android_ota' do
  frequency 'weekly'
  retention 2
  action :enable
  only_if { node['provider'] == 'aws' }
end
