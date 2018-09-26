#
# Cookbook Name:: prom-default
# Recipe:: repo
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Add the promethean yum repo
#

yum_repository = node['yum']['yumserver']
gpg_check      = node['yum']['gpgcheck']
gpg_pubkey_id  = node['yum']['gpg_pubkey_id']

# clean up the yum cache
execute 'clean' do
  command 'yum clean expire-cache'
  action :nothing
end

# Promethean repo
template '/etc/yum.repos.d/promethean.repo' do
  case node['platform_version'].to_i
  when 7
    source 'promethean.repo7.erb'
  when 6
    source 'promethean.repo.erb'
  end
  variables(
   :yum_repository => yum_repository,
  )
  notifies :run, 'execute[clean]', :immediately
end

# RPM file signing
if gpg_check == '1'

  cookbook_file '/etc/pki/rpm-gpg/RPM-GPG-KEY-Promethean' do
    # gpg pubkey file is fingerprinted with the public key id
    # to ensure it matches infrastructure setting
    source "promethean-rpm-gpg-#{gpg_pubkey_id}.key"
    owner 'root'
    group 'root'
    mode '0600'
  end
end


