###########################################
# Cookbook Name:: prom-cloudwatch
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
###########################################

# Grab the aws creds from databag aws-sdk:main
awscreds = data_bag_item("aws-sdk", "main")
awslogs = data_bag_item("awslogs","main")

# Base directory
base_directory = awslogs['base_directory']

# Retention length for logs (in days)
retention_in_days = awslogs['retention_in_days']

# The install script reads this file so as not to ask any questions
install_config_file = "#{base_directory}/etc/install/awslogs.conf"

# First we create the install directory
# but only if the aws attributes are present
directory "#{base_directory}/etc/install" do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
  action :create
  only_if do node.attribute?('aws') and node['aws'].attribute?('region') end
end

# Grab the latest awslogs setup script
# but only if the above install directory was created
# and dump the script in /var/awslogs/etc/install dir 
# so that it doesn't get overwritten by the install script
remote_file "#{base_directory}/etc/install/awslogs-agent-setup.py" do
  source 'https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py'
  mode '0777'
  owner 'root'
  group 'root'
  action :create
  retries 3
  only_if do ::File.directory?("#{base_directory}/etc/install") end
end

# Create a link to /etc/awslog just for convenience
# but only if the /var/awslogs/etc dir exists
link '/etc/awslogs' do
  to "#{base_directory}/etc"
  only_if do File.directory?("#{base_directory}/etc") end
end

# Dump an AWS Logs config file in the install dir
# this way it doesn't get overwritten by the install process
# the install process will read this conf file 
# If the file is new or newer, the `Run_AWS_Script` clause will get run
template "#{base_directory}/etc/install/awslogs.conf" do 
  source 'awslogs.conf.erb'
  notifies :run, 'execute[Run_AWS_Script]', :immediate
  variables(
    :logs => awslogs['logs']
  )
  only_if do ::File.directory?("#{base_directory}/etc/install") end 
end


# Run the `awslogs-agent-setup.py` script, but only when "notified"
# by "notified" I mean called by the previous clause
execute 'Run_AWS_Script' do
  command "#{base_directory}/etc/install/awslogs-agent-setup.py --non-interactive --region=#{node['aws']['region']} --configfile=#{install_config_file}"
  action :nothing
  supports :run => true
  only_if do ::File.exists?("#{base_directory}/etc/install/awslogs-agent-setup.py") end
end

# Run a command on the `awslogs` service when "notified"
service 'awslogs' do
  action :enable
  supports :status => true, :start => true, :stop => true 
  only_if do ::File.directory?("#{base_directory}/etc/install") end
end

# Create the `.aws` directory in root's home
# if it doesn't exist
directory '/root/.aws' do 
  owner 'root'
  group 'root'
  mode '0600'
  action :create
end

# Drop a `credentials` file 
# in the `.aws` directory 
# populated by the AWS credentials found in the data bag
# if the contents change or if it's a new file,
# the `awslogs` service will get restarted
template '/root/.aws/credentials' do 
  source 'credentials.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    :aws_access_key_id => awscreds['aws_access_key_id'], 
    :aws_secret_access_key => awscreds['aws_secret_access_key']
  )
  action :create
  notifies :restart, 'service[awslogs]', :delayed
  only_if do ::File.directory?('/root/.aws') end
end



