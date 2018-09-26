#
# Cookbook Name:: cachet
# Recipe:: default
#
# Copyright 2016, Promethean, Inc
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'prom-default'
include_recipe 'prom-default::repo'
include_recipe 'prom-default::hostsfile'

# Cachet requires a CentOS 7 based instance
if node['platform_version'] >= '7'

  # Pull email server information from data bag 
  begin
    mailserver = data_bag_item("email", "#{node['emailservice']}")
  rescue Net::HTTPServerException
    Chef::Log.info("No email information found in data bag item #{node['emailservice']}")
  end

  execute 'install_cachet' do
    command '/opt/cachet-setup.sh'
    action :nothing
  end

  # Modified Cachet automated installation script
  template '/opt/cachet-setup.sh' do
    source 'cachet-setup.sh.erb'
    owner  'root'
    group  'root'
    mode   '0755' 
    variables(
      :smtpserver => "#{mailserver['smtpserver']}",
      :smtpport   => '587',
      :smtpuser   => mailserver['smtpuser'],
      :smtppass   => mailserver['smtppass']
    )
    # These work, but an initial manual run of the script is preferred
    #notifies :run, "execute[install_cachet]"
    #not_if { ::File.directory?('/var/www/Cachet') }
  end

  template '/etc/logrotate.d/nginx' do
    source 'logrotate-nginx.erb'
    owner  'root'
    group  'root'
    mode   '0644'
  end

  # Set up status ELB for Cachet
  if node['provider'] == 'aws'
    include_recipe 'promaws::default'
    aws = data_bag_item('aws-sdk', 'main')
    aws_elastic_lb "#{node['cachet']['cachet_elb']}" do
      aws_access_key aws['aws_access_key_id']
      aws_secret_access_key aws['aws_secret_access_key']
      name node['cachet']['cachet_elb']
      region node['aws_node_region'] if node['requires_aws_region']
      action :register
    end
  end
else
  Chef::Log.fatal!('This recipe requires CentOS 7, failing chef-client run!', 1)
end
