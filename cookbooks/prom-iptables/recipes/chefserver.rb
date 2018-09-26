#
# Cookbook Name:: prom-iptables
# Recipe:: chefserver
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "iptables::default"
%w{port_sshd port_postfix port_souschef port_chefserver}.each do |port|
  iptables_rule port
end
service "iptables" do
  supports :stop => true, :start => true, :restart => true, :reload => true, :status => true, :enable => true
  action [:start, :enable]
end

