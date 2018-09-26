#
# Cookbook Name:: prom-mailrelay
# Recipe:: default
#
# Copyright 2016, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
%w{postfix cyrus-sasl cyrus-sasl-plain}.each do |package|
  yum_package package do
    action :upgrade
  end
end
