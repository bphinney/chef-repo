#
# Cookbook Name:: promethean
# Recipe:: dotcmsfront
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-presearch"

#Newrelic attributes
if node.recipes.include?('newrelic')
  node.default['newrelic']['application_monitoring']['app_name'] = "dotcms"
end

service 'httpd' do
  if node['platform_version'].to_i == "7" 
    stop_command '/bin/systemctl stop httpd'
    start_command '/bin/systemctl start httpd'
    reload_command '/usr/sbin/apachectl graceful'
    restart_command '/bin/systemctl restart httpd'
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end 
  supports :stop => true, :start => true, :restart => true, :status => true, :graceful => true
  action :nothing
end

execute "configcheck" do
  command "apachectl configtest"
  action :nothing
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
end

##################################
## Start of dotcms installation ##
##################################

unless node['dotcms']['widgetservername'].nil? || node['dotcms']['widgetservername'].empty?

  directory "/opt/www/dotcms" do
    recursive true
  end

  dotcmsworkers = []
  if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef solo does not support search.")
  else
    $presearch_node['dotcms_nodes'].each do |worker|
      dotcmsworkers << worker
    end
  end

  dotcmsworkers.uniq! { |a| a.ipaddress }
  dotcmsworkers.sort! { |a,b| a.ipaddress <=> b.ipaddress }
  template "/etc/httpd/conf.d/dotcms.proxy" do
    source "dotcms.proxy.erb"
    owner  "root"
    group  "root"
    mode   "0644"
    notifies :run, "execute[configcheck]"
    variables(:dotcmsworkers => dotcmsworkers,
              :countryblock => node['countryblock'].split(",")
             )
    not_if {dotcmsworkers.nil? || dotcmsworkers.empty?}
  end

  template "/etc/httpd/conf.d/dotcms.conf" do
    source "dotcms.conf.erb"
    owner  "root"
    group  "root"
    mode   "0644"
    notifies :run, "execute[configcheck]"
    not_if { node['dotcms']['widgetservername'].nil? || node['dotcms']['widgetservername'].empty? }
  end

  include_recipe "prom-http::update_htaccess"

  #execute "connectiontest-create" do
  #  command "seq 1 1388888 > /opt/www/dotcms/connectiontest; chown apache. /opt/www/dotcms/connectiontest"
  #  only_if { node.chef_environment == "prod" }
  #  not_if "test -f /opt/www/dotcms/connectiontest"
  #  action :run
  #end
else
  file "/etc/httpd/conf.d/dotcms.conf" do
    action :delete
    only_if { node['dotcms']['widgetservername'].nil? || node['dotcms']['widgetservername'].empty? }
  end

end

