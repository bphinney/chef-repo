###########################################
# Cookbook Name:: prom-cloudwatch
# Recipe:: set_retention
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
###########################################
require 'colorize'

# Grab the goodies from the data bag
awslogs = data_bag_item("awslogs","main")

# Base directory
base_directory = awslogs['base_directory']

# Retention in days
retention_in_days = awslogs['retention_in_days']

if ! ::File.exists?("#{base_directory}/bin/aws")
  puts
  puts "#{base_directory}/bin/aws is missing. So I'm just gonna die.".red
  puts 
  return
end

awslogs['logs'].each do |z|
    s = `#{base_directory}/bin/aws logs describe-log-groups --region=#{node['aws']['region']} |grep -A1 #{z['group_name']}|grep retentionInDays`

    if s != ''
      s.gsub!(/["|,]/,'').strip()
      current_retention = s.strip().split(':')[1].strip
      puts "Current Retention: "+current_retention
    else
      current_retention = ''
    end

  if current_retention == '' or retention_in_days != current_retention
    group = z['group_name']
    execute "Set retention for #{group} to #{retention_in_days} days in #{node['aws']['region']}" do
      command "#{base_directory}/bin/aws logs put-retention-policy --log-group-name #{z['group_name']} --retention-in-days #{retention_in_days} --region=#{node['aws']['region']}"
      only_if do ::File.exists?('/var/awslogs/bin/aws') and 
      node.attribute?('aws') and node['aws'].attribute?('region') end
    end
  end
end

