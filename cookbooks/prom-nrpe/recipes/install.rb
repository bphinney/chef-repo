#
# Cookbook Name:: prom-nrpe
# Recipe:: install
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'prom-presearch'
include_recipe 'prom-default::repo'

node.default['nrpe']['install_yum-epel'] = true


service 'nrpe' do
  supports :restart => true, :reload => true, :status => true
  action :nothing
end

if platform_family?('rhel') 
  yum_package 'nagios-nrpe' do
    action :upgrade
    notifies :restart, "service[nrpe]"
  end
end

if platform_family?('rhel')
  %w{nagios-plugins nagios-plugins-disk nagios-plugins-load nagios-plugins-procs nagios-plugins-users}.each do |package|
    yum_package package do
      action :upgrade
      notifies :restart, "service[nrpe]"
    end
  end
end

solonode = node
nagnodes = []

if Chef::Config['solo']
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search unless you install the chef-solo-search cookbook.')
  nagnodes = solonode['ipaddress']
else
  # search for nagios servers and add them to the nagnodes array as well
  if node['nrpe']['multi_environment_monitoring']
    $presearch_node['nagios_nodes'].each do |nag|
      unless nag['ipaddress'].nil?
        nagnodes << nag['ipaddress']
      end
    end
  end
end

include_dir = "#{node['nrpe']['conf_dir']}/nrpe.d"

directory include_dir do
  owner 'root'
  group node['nrpe']['group']
  mode '0750'
end

template "#{node['nrpe']['conf_dir']}/nrpe.cfg" do
  source 'nrpe.cfg.erb'
  owner 'root'
  group node['nrpe']['group']
  mode '0640'
  variables(
    :nagnodes => nagnodes.uniq.sort,
    :include_dir => include_dir
  )
  notifies :restart, "service[nrpe]"
end

service 'nrpe' do 
  action [:start,:enable]
end


# The updating of the list of checks.
ruby_block 'updating of the list of checks' do
  block do
    checks = run_context.resource_collection.select { |r| r.is_a?(Chef::Resource::NrpeCheck) && r.action == [:add] }.map(&:command_name)
    node.set['nrpe']['checks'] = checks
  end
end

