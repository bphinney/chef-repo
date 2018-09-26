#
# Cookbook Name:: prom-default
# Recipe:: yumepel
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Configures epel repositories for a node

include_recipe "yum::default"

if node['platform_version'].to_i == '7'
  yum_repository 'epel' do
    description 'Extra Packages for Enterprise Linux 7 - Standard - $basearch'
    enabled true
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7'
    mirrorlist 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch'
    sslverify true
    action :create
  end

elsif node['platform_version'].to_i == '6'
  yum_repository 'epel' do
    description 'Extra Packages for Enterprise Linux 6 - $basearch'
    enabled true
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch'
    sslverify true
    action :create
  end

  yum_repository 'epel-debuginfo' do
    description 'Extra Packages for Enterprise Linux 6 - $basearch - Debug'
    enabled false
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-debug-6&arch=$basearch'
    sslverify true
    action :create
  end

  yum_repository 'epel-source' do
    description 'Extra Packages for Enterprise Linux 6 - $basearch - Source'
    enabled false
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-source-6&arch=$basearch'
    sslverify true
    action :create
  end

  yum_repository 'epel-testing-debuginfo' do
    description 'Extra Packages for Enterprise Linux 6 - Testing - $basearch Debug'
    enabled false
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=testing-debug-epel6&arch=$basearch'
    sslverify true
    action :create
  end

  yum_repository 'epel-testing-source' do
    description 'Extra Packages for Enterprise Linux 6 - Testing - $basearch Source'
    enabled false
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=testing-source-epel6&arch=$basearch'
    sslverify true
    action :create
  end

  yum_repository 'epel-testing' do
    description 'Extra Packages for Enterprise Linux 6 - Testing - $basearch'
    enabled false
    failovermethod 'priority'
    gpgcheck true
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=testing-epel6&arch=$basearch'
    sslverify true
    action :create
  end
end
