#
# Cookbook Name:: prom-beaver
# Recipe:: beaver_logs
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#

service "beaver" do
  supports :stop => true, :start => true, :restart => true, :status => true, :enable => true
  action :nothing
end

clientenvironment = node.chef_environment

#######################################################
## Backend Log Configuration                         ##
#######################################################
# /opt/tomcat/logs/catalina.out
template "/etc/beaver/conf.d/catalina.conf" do
  source 'beaver_conf_catalina.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.recipes.include?('prom-activtomcat::activtomcat') }
end

# Activfoundation - /opt/tomcat/logs/activfoundation.log
template "/etc/beaver/conf.d/activfoundation.conf" do
  source 'beaver_conf_activfoundation.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.run_list.roles.include?('backend') ||  
            node.run_list.roles.include?('flipchart') }
end

#######################################################
## Collabserver Log Configuration                         ##
#######################################################
# /opt/vertx/logs/collabserver.log
template "/etc/beaver/conf.d/collabserver.conf" do
  source 'beaver_conf_collabserver.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.run_list.roles.include?('collabserver') }
end

#######################################################
## Frontend Log Configuration                        ##
#######################################################
# /var/log/httpd/httpd.log
template "/etc/beaver/conf.d/httpd.conf" do
  source 'beaver_conf_httpd.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.run_list.roles.include?('frontend') }
end

template "/etc/beaver/conf.d/modsec.conf" do
  source 'beaver_conf_modsec.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.run_list.roles.include?('frontend') }
end

#######################################################
## Collabfront Log Configuration                     ##
#######################################################
# /var/log/haproxy.log-*
template "/etc/beaver/conf.d/haproxy.conf" do
  source 'beaver_conf_haproxy.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.run_list.roles.include?('collabfront') }
end

#######################################################
## PRworld Log Configuration                         ##
#######################################################
# /opt/dotCMS/dotserver/tomcat-8.0.18/webapps/ROOT/dotsecure/logs/*.log
template "/etc/beaver/conf.d/prworld.conf" do
  source 'beaver_conf_prworld.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.run_list.roles.include?('prworld') }
end


#######################################################
## Elasticsearch Log Configuration                     ##
#######################################################
# /usr/local/var/log/elasticsearch/foundation*.log
template "/etc/beaver/conf.d/elasticsearch.conf" do
  source 'beaver_conf_elasticsearch.erb'
  owner 'root'
  group 'root'
  mode  '0644'
  notifies :restart, "service[beaver]"
  only_if { node.recipes.include?('prom-elasticsearch') }
end

# Cron to restart beaver agent

cron "restart_beaver_agent" do
  if node.attribute?('centos') && node['platform_version'].to_i == '7'
    command '/bin/systemctl restart beaver > /dev/null 2>&1'
  else
    command "/sbin/service beaver restart > /dev/null 2>&1"
  end
  minute  "33"
  hour    "3"
end
