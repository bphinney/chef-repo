#
# Cookbook Name:: prom-sftp
# Recipe:: sftp-server
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

# Install aws snapshot backups
promaws_ebssnap 'sftp-server' do
  frequency 'weekly'
  retention 2
  action :enable
  only_if { node['provider'] == 'aws' }
end
