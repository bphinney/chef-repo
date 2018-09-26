#
# Cookbook Name:: prom-logship
#
# Recipe:: default
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#
# FileBeat Docs - https://www.elastic.co/guide/en/beats/libbeat/current/index.html
#
yum_package 'filebeat' do
  action :upgrade
  notifies :restart, 'service[filebeat]'
end

#if ::File.exist?('/etc/init.d/beaver')
#  execute 'beaver'do
#    command '/etc/init.d/beaver stop'
#  end

#  file '/etc/init.d/beaver' do
#    action :delete
#    force_unlink true
#  end
#end

#if  ::File.directory?('/etc/beaver')
#  directory '/etc/beaver' do
#    action :delete
#  end
#end

%w{/var/log/filebeat /etc/filebeat/conf.d}.each do |newdir|
  directory newdir do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    not_if { ::File.directory?(newdir) }
  end
end

template '/etc/filebeat/filebeat.yml' do
  source 'filebeat.yml.erb'
  notifies :restart, 'service[filebeat]'
end

if ::File.directory?('/opt/tomcat/logs')
  template '/etc/filebeat/conf.d/activtomcat.yml' do 
    source 'activtomcat.yml.erb'
  end
end

if ::File.directory?('/opt/vertx/logs')
  template '/etc/filebeat/conf.d/vertx.yml' do 
    source 'vertx.yml.erb'
  end
end

if ::File.directory?('/var/log/httpd')
  template '/etc/filebeat/conf.d/httpd.yml' do 
    source 'httpd.yml.erb'
  end
end

if ::File.directory?('/opt/dotCMS/dotserver/tomcat-7.0.54/logs')
  template '/etc/filebeat/conf.d/dotcms.yml' do 
    source 'dotcms.yml.erb'
  end
end

service 'filebeat' do 
  supports :stop => true, :start => true, :restart => true, :status => true
  action [:enable, :start]
end
