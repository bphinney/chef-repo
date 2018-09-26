#
# Cookbook Name:: prom-nrpe
# Recipe:: default
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

directory "/etc/nagios" do
  action :create
  not_if { File.exists?("/etc/nagios") }
end

node.override['nrpe']['dont_blame_nrpe']    = 1

node.default['nrpe']['server_role'] = "monitoring"
node.default['nrpe']['multi_environment_monitoring'] = true
node.default['nrpe']['plugin_dir'] = "/usr/lib64/nagios/plugins"
node.default['nrpe']['install_yum-epel'] = false

include_recipe "prom-nrpe::install"
#include_recipe "nrpe"

if node.recipes.include?('atlassian::bamboo')
  node.override['nrpe']['checks']['load']['warning'] = "25,20,15"
  node.override['nrpe']['checks']['load']['critical'] = "40,35,30"
else
  node.override['nrpe']['checks']['load']['warning'] = "8"
  node.override['nrpe']['checks']['load']['critical'] = "10"
end
node.override['nrpe']['checks']['disk']['warning'] = "20%"
node.override['nrpe']['checks']['disk']['critical'] = "10%"
node.override['nrpe']['checks']['mem']['warning'] = "85"
node.override['nrpe']['checks']['mem']['critical'] = "95"

nrpe_check "check_load" do
  command "#{node['nrpe']['plugin_dir']}/check_load"
  warning_condition node['nrpe']['checks']['load']['warning']
  critical_condition node['nrpe']['checks']['load']['critical']
  action :add
end

nrpe_check "check_disk" do
  command "#{node['nrpe']['plugin_dir']}/check_disk"
  warning_condition node['nrpe']['checks']['disk']['warning']
  critical_condition node['nrpe']['checks']['disk']['critical']
  action :add
end

nrpe_check "check_mem" do
  command "#{node['nrpe']['plugin_dir']}/check_mem -u -C"
  warning_condition node['nrpe']['checks']['mem']['warning']
  critical_condition node['nrpe']['checks']['mem']['critical']
  action :add
end

template "#{node['nrpe']['plugin_dir']}/check_mem" do
  source "check_mem.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

template "#{node['nrpe']['plugin_dir']}/check_logfiles" do
  source "check_logfiles.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('logstash_server') ||
            node.run_list.roles.include?('backend') }
end

nrpe_check "remount_volume" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/remount_volume $ARG1$ $ARG2$"
  action :add
  only_if { node.run_list.roles.include?('glusterfs') }
end
template "#{node['nrpe']['plugin_dir']}/remount_volume" do
  source "remount_volume.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('glusterfs') }
end
nrpe_check "restart_glusterd" do
  command "/usr/bin/sudo /sbin/service glusterd restart"
  action :add
  only_if { node.run_list.roles.include?('glusterfs') }
end

if node.run_list.roles.include?('backend')
  nrpe_check "check_logfiles" do
    command "#{node['nrpe']['plugin_dir']}/check_logfiles --tag=$ARG1$ --logfile=$ARG2$ --warningpattern=$ARG3$ --criticalpattern=$ARG4$"
    action :add
  end
  nrpe_check "check_logfiles_cfg" do
    command "#{node['nrpe']['plugin_dir']}/check_logfiles --config=$ARG1$"
    action :add
  end
  nrpe_check "check_connections" do
    command command "#{node['nrpe']['plugin_dir']}/check_connections"
    action :add
  end
  template "#{node['nrpe']['plugin_dir']}/check_connections" do
    if node['platform_version'].to_i == '7'
      source "check_connections-cent7.erb"
    else
      source "check_connections.erb"
    end
    owner "root"
    group "root"
    mode "0755"
  end
  nrpe_check "restart_activfoundation" do
    if node['platform_version'].to_i == '7'
      command "/usr/bin/sudo /usr/bin/systemctl restart activtomcat"
    else
      command "/usr/bin/sudo /sbin/service activtomcat restart"
    end
    action :add
  end
  nrpe_check "start_activtomcat" do
    if node['platform_version'].to_i == '7'
      command "/usr/bin/sudo /usr/bin/systemctl restart activtomcat"
    else
      command "/usr/bin/sudo /sbin/service activtomcat start"
    end
    action :add
  end

end

if node.run_list.roles.include?('collabfront')
  nrpe_check "restart_haproxy" do
    if node['platform_version'].to_i == '7'
      command "/usr/bin/sudo /usr/bin/systemctl restart haproxy"
    else
    command "/usr/bin/sudo /sbin/service haproxy restart"
    end
    action :add
  end
  nrpe_check "check_backend" do
    command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_backend"
    action :add
  end
  template "#{node['nrpe']['plugin_dir']}/check_backend" do
    source "check_backend.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end
end

if node.recipes.include?('prom-services::emailservice')
  nrpe_check "check_emailsrv" do
    command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_emailsrv"
    action :add
  end
  template "#{node['nrpe']['plugin_dir']}/check_emailsrv" do
    source "check_emailsrv.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end
  nrpe_check "restart_emailsrv" do
    if node['platform_version'].to_i == '7'
      command "/usr/bin/sudo /usr/bin/systemctl restart emailsrv"
    else
      command "/usr/bin/sudo /sbin/service emailsrv restart"
    end
    action :add
  end
end

if node.recipes.include?('atlassian::bamboo')
  node.override['nrpe']['checks']['load']['warning'] = "10,20,30"
  node.override['nrpe']['checks']['load']['critical'] = "10,20,30"
end

if node.run_list.roles.include?('monitoring')
  template "#{node['nrpe']['plugin_dir']}/check_prworld" do
    source "check_prworld.erb"
    owner  "nagios"
    group  "nagios"
    mode   "0755"
  end
  template "#{node['nrpe']['plugin_dir']}/restart_prwprod" do
    source "restart_prwprod.erb"
    owner  "nagios"
    group  "nagios"
    mode   "0755"
  end
end

nrpe_check "restart_dotcms" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl stop dotcms; sleep 15; /usr/bin/sudo /usr/bin/systemctl start dotcms"
  else
    command "/usr/bin/sudo /sbin/service dotcms stop; sleep 15; /usr/bin/sudo /sbin/service dotcms start"
  end
  action :add
  only_if { node.recipes.include?('dotcms::dotcms') || node.run_list.roles.include?('prworld') }
end

nrpe_check "restart_apache" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart httpd"
  else
    command "/usr/bin/sudo /sbin/service httpd restart"
  end
  action :add
  only_if { node.run_list.roles.include?('frontend') || node.recipes.include?('prworld::prworldfront') }
end

nrpe_check "restart_proftpd" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart proftpd"
  else
    command "/usr/bin/sudo /sbin/service proftpd restart"
  end
  action :add
  only_if { node.recipes.include?('prom-sftp::sftp-server') }
end

nrpe_check "restart_rabbitmq" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart rabbitmq-server"
  else
    command "/usr/bin/sudo /sbin/service rabbitmq-server restart"
  end
  action :add
  only_if { node.run_list.roles.include?('rabbitmq') }
end

template "#{node['nrpe']['plugin_dir']}/check_elasticsearch" do
  source "check_elasticsearch.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('elasticsearch') }
end
nrpe_check "restart_elasticsearch" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart elasticsearch"
  else
    command "/usr/bin/sudo /sbin/service elasticsearch restart"
  end
  action :add
  only_if { node.run_list.roles.include?('elasticsearch') }
end
nrpe_check "check_elasticsearch" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_elasticsearch"
  action :add
  only_if { node.run_list.roles.include?('elasticsearch') }
end

template "#{node['nrpe']['plugin_dir']}/check_beaver_agent" do
  source "check_beaver_agent.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.recipes.include?('prom-beaver::beaver_logs') }
end

nrpe_check "check_beaver_agent" do
  command "#{node['nrpe']['plugin_dir']}/check_beaver_agent"
  action :add
  only_if { node.recipes.include?('prom-beaver::beaver_logs') }
end
nrpe_check "restart_beaver_agent" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart beaver"
  else
    command "/usr/bin/sudo /sbin/service beaver restart"
  end
  action :add
  only_if { node.recipes.include?('prom-beaver::beaver_logs') }
end

template "#{node['nrpe']['plugin_dir']}/check_logstash_server" do
  source "check_logstash_server.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('logstash_server') }
end

template "#{node['nrpe']['plugin_dir']}/check_redis" do
  source "check_redis.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "check_logfiles_redis" do
  command "#{node['nrpe']['plugin_dir']}/check_logfiles --tag=$ARG1$ --logfile=$ARG2$ --warningpattern=$ARG3$ --criticalpattern=$ARG4$"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end
nrpe_check "check_logstash_server" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_logstash_server"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end
nrpe_check "check_logfiles" do
  command "#{node['nrpe']['plugin_dir']}/check_logfiles --tag=$ARG1$ --logfile=$ARG2$ --warningpattern=$ARG3$ --criticalpattern=$ARG4$"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end
nrpe_check "check_logfiles_cfg" do
  command "#{node['nrpe']['plugin_dir']}/check_logfiles --config=$ARG1$"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "restart_logstash_server" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart logstash"
  else
    command "/usr/bin/sudo /sbin/service/logstash restart"
  end
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "restart_redis" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart redis"
  else
    command "/usr/bin/sudo /sbin/service/redis restart"
  end
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "restart_zookeeper" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart zookeeper"
  else
    command "/usr/bin/sudo /sbin/service zookeeper restart"
  end
  only_if { node.recipes.include?('zookeeper') }
  action :add
end

nrpe_check "restart_jasper" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart jasper"
  else
    command "/usr/bin/sudo /sbin/service jasper restart"
  end
  only_if { node.recipes.include?('jasper::jasper') }
  action :add
end
template "#{node['nrpe']['plugin_dir']}/check_jasper" do
  source "check_jasper.erb"
  owner  "root"
  group  "root"
  owner  "root"
  mode   "0755"
  only_if { node.recipes.include?('jasper::jasper') }
end
nrpe_check "check_jasper" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_jasper"
  action :add
  only_if { node.recipes.include?('jasper::jasper') }
end

directory "/var/tmp/check_logfiles" do
  recursive true
  owner "nagios"
  group "nagios"
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "restart_activtomcat" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart activtomcat"
  else
    command "/usr/bin/sudo /sbin/service activtomcat restart"
  end
  action :add
  only_if { node.recipes.include?('prom-activtomcat::activtomcat') }
end

nrpe_check "start_activtomcat" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl start activtomcat"
  else
    command "/usr/bin/sudo /sbin/service activtomcat start"
  end
  action :add
  only_if { node.recipes.include?('prom-activtomcat::activtomcat') }
end

nrpe_check "restart_flipchart" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart activtomcat"
  else
    command "/usr/bin/sudo /sbin/service activtomcat restart"
  end
  action :add
  only_if { node.run_list.roles.include?('flipchart') }
end

template "#{node['nrpe']['plugin_dir']}/check_glusterfs" do
  source "nagios_checkglusterfs.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('glusterfs') }
end

template "#{node['nrpe']['plugin_dir']}/check_ipsec" do
  source "nagios_checkipsec.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.recipes.include?('atlassian::jira') }
end

package "bc" do
  action :upgrade
  only_if { node.recipes.include?('glusterfs') }
end
nrpe_check "check_glusterfs" do
  command "#{node['nrpe']['plugin_dir']}/check_glusterfs -v $ARG1$ -n $ARG2$ -w $ARG3$ -c $ARG4$"
  action :add
  only_if { node.run_list.roles.include?('glusterfs') }
end

nrpe_check "check_ipsec" do
  command "#{node['nrpe']['plugin_dir']}/check_ipsec -H $ARG1$"
  action :add
  only_if { node.recipes.include?('atlassian::jira') }
end

template "/etc/sudoers.d/nagios" do
  source "nagios-sudo.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

nrpe_check "restart_collabserver" do
  if node['platform_version'].to_i == '7'
    command "/usr/bin/sudo /usr/bin/systemctl restart collabserver"
  else
    command "/usr/bin/sudo /sbin/service collabserver restart"
end
  action :add
  only_if { node.run_list.roles.include?('collabserver') }
end

nrpe_check "check_redismem" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_redismem"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "check_redis" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_redis"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end

template "/usr/lib64/nagios/plugins/check_redismem" do
  source "check_redismem.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('logstash_server') }
end

nrpe_check "check_logstashmem" do
  command "/usr/bin/sudo #{node['nrpe']['plugin_dir']}/check_logstashmem"
  action :add
  only_if { node.run_list.roles.include?('logstash_server') }
end

template "/usr/lib64/nagios/plugins/check_logstashmem" do
  source "check_logstashmem.erb"
  owner  "root"
  group  "root"
  mode   "0755"
  only_if { node.run_list.roles.include?('logstash_server') }
end
