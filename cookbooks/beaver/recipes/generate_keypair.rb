#
# Cookbook Name:: beaver
# Recipe:: default
#
# Copyright 2014, promethean/rsavage
#
# Generate a ssh keypair and expose the public key on the node so that
# a central logging instance such as a logstash host can grant access.
# This allows for secure tunnelling of the logs to the log host.
private_key = "#{node['beaver']['config_path']}/#{node['beaver']['ssh_key_file']}"
execute 'Create a public key pair to access the central logging host' do
  command "ssh-keygen -P '' -f #{private_key}"
  creates private_key
end

if File.file?(private_key)
  public_key = File.open("#{private_key}.pub", 'rb') { |file| file.read }
  node.set['beaver']['public_key'] = public_key
end
