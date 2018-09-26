#
# Cookbook Name:: beaver
# Recipe:: default
#
# Copyright 2014, promethean/rsavage 
#

default['beaver'] = {
  'version' => '36.2.0',
  'log_path' => '/var/log',
  'log_file' => 'beaver.log',
  'generate_keypair' => false,
  'ssh_key_file' => 'logger',
  'config_path' => '/etc/beaver',
  'config_file' => 'beaver.conf',
  'configuration' => {
    'respawn_delay' => 3,
    'max_failure' => 7
  },
  'files' => []
}

if node['platform_family'] == 'centos'
  default['beaver']['files'] = [
    {
      'path' => '/var/log/messages',
      'type' => 'syslog',
      'tags' => 'sys,syslog'
    }, {
      'path' => '/var/log/secure',
      'type' => 'syslog',
      'tags' => 'auth'
    }
  ]
end
