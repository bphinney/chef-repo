#
# Cookbook Name:: atlassian-yumrepo
# Recipe:: yumrepo-sign
#
# Copyright 2016, Promethean
# All rights reserved - Do Not Redistribute
#
# Uses preconfigured pgp key to allow for automated
# rpm package signing
#

include_recipe 'atlassian-yumrepo::yumrepo-gpg'

gpg_user       = node['yum']['gpg_user']
# Secure private Key Passphrase
gpg_passphrase = node['yum']['gpg_passphrase']
gpg_trackfile  = '/tmp/signed_rpms.txt'

# Local file to track current sign state of rpm files
file gpg_trackfile do
  owner  'root'
  group  'root'
  mode   '0755' 
  action :create_if_missing
end

# 'expect' dependency for required prompt interaction during signing
yum_package 'expect' do
  action :install
end

# RPM sigining script
template '/usr/bin/rpm-gpgsign' do
  source 'rpm-gpgsign.erb'
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
  variables(
    gpg_user:       gpg_user,
    gpg_passphrase: gpg_passphrase,
    gpg_trackfile:  gpg_trackfile
  )
end
