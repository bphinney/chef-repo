#
# Cookbook Name:: promethean
# Recipe:: stagemonitorclient
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#
include_recipe "prom-default"
include_recipe "prom-default::repo"
include_recipe "prom-presearch"
include_recipe "yum::default"


# TODO - Set stagemonitor version with other applications, clean this up.
stagemonitor_version = "#{node['stagemonitor']['version']}" == '' ? "#{node['applications']['stagemonitor_version']}" : "#{node['stagemonitor']['version']}"

$presearch_node['metrics_host'].each do |smnode|
  $smserverip = smnode['ipaddress']
end

# Common stagemonitor client components
yum_package "stagemonitor" do
  action :install
  version stagemonitor_version
  allow_downgrade true
  not_if { stagemonitor_version == '0.0.0-1' }
end

# Modified installation for 0.14.1-0, utilizing javassist.
# Changing versioning from existing 2.6.2-2, which doesn't make sense.
if stagemonitor_version == "0.14.1-0"

  # Quick patch to set single application for 0.14.1-0
  application    = "activfoundation"
  reloadable     = node['stagemonitor']['reloadable']
  browser_widget = node['stagemonitor']['browser_widget']
  
  template "/opt/stagemonitor/lib/stagemonitor.properties" do
    source "stagemonitor.properties.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0644"
    variables(
      :smserverip     => $smserverip,
      :application    => application,
      :reloadable     => reloadable,
      :browser_widget => browser_widget
    )
    if node['stagemonitor']['client_active'] == "true"
      action :create
    else
      action :delete
    end
    if reloadable == "false"
      notifies :restart, "service[activtomcat]"
    end
  end

  # context.xml templates to initiate classloading
  template "/opt/tomcat/conf/Catalina/localhost/#{application}.xml" do
    source "stagemonitor.xml.erb"
    owner  "tomcat"
    group  "tomcat"
    mode   "0644"
    variables(
      :application    => application,
      :reloadable     => reloadable
    )
    if node['stagemonitor']['client_active'] == "true"
      action :create
    else
      action :delete
    end
    notifies :restart, "service[activtomcat]"
  end

# Original 2.6.1-2 installation components.     
else

  # Per Application components
  node['stagemonitor']['sm_apps'].each do |application,flag|

    # Master shutoff switch based on state of client_active attribute.
    if node['stagemonitor']['client_active'] == 'false' || node['stagemonitor']['client_active'].nil? || node['stagemonitor']['client_active'].empty?
      metrics_status = "false"
      reloadable     = "false"
      browser_widget = "false"
    else
      metrics_status = flag['metrics_active']
      reloadable     = flag['reloadable']
      browser_widget = flag['browser_widget']
    end

    if metrics_status == "true"
      yum_package "stagemonitor-#{application}" do
         action :install
         version stagemonitor_version
         allow_downgrade true
         not_if { stagemonitor_version == '0.0.0-1' }
      end
    end

    template "/opt/stagemonitor-#{application}/lib/stagemonitor.properties" do
      source "stagemonitor.properties.erb"
      owner  "tomcat"
      group  "tomcat"
      mode   "0644"
      variables(
        :smserverip     => $smserverip,
        :application    => application,
        :reloadable     => reloadable,
        :browser_widget => browser_widget
      )
      if metrics_status == "true"
        action :create
      else
        action :delete
      end
      if reloadable == "false"
        notifies :restart, "service[activtomcat]"
      end
    end

    directory "/opt/tomcat/conf/Catalina/localhost" do
      owner "tomcat"
      group "tomcat"
      mode  "0755"
      recursive true
      if metrics_status == "true"
        action :create
      elsif metrics_status == "false" and node['stagemonitor']['profiling_active'] == "true"
        action :create
      else
        action :delete
      end    
    end
 
    # context.xml templates per application for proper classloading
    template "/opt/tomcat/conf/Catalina/localhost/#{application}.xml" do
      source "stagemonitor.xml.erb"
      owner  "tomcat"
      group  "tomcat"
      mode   "0755"
      variables(
        :application    => application,
        :client_install => metrics_status,
        :reloadable     => reloadable
  
      )
      # Only create placeholder contexts if profiling and metrics are active.
      if metrics_status == "true"
        action :create
      elsif metrics_status == "false" and node['stagemonitor']['profiling_active'] == "true"
        action :create
      else
        action :delete
      end
      notifies :restart, "service[activtomcat]"
    end

    # Removal of directory and recursive
    directory "/opt/tomcat/conf/Catalina" do
      owner "tomcat"
      group "tomcat"
      mode  "0755"
      recursive true
      if metrics_status == "true"
        action :create
      elsif metrics_status == "false" and node['stagemonitor']['profiling_active'] == "true"
        action :create
      else
        action :delete
      end
    end
  end

  # Weaving for profiling initiated through setenv.sh across all tomcat apps
  unless node['stagemonitor']['profiling_active'] == 'false' || node['stagemonitor']['profiling_active'].nil? || node['stagemonitor']['profiling_active'].empty?
    template "/opt/stagemonitor/lib/aop.xml" do
      source "aop.xml.erb"
      owner  "tomcat"
      group  "tomcat"
      mode   "0644"
    end

    template "/opt/stagemonitor/lib/stagemonitor_env.sh" do
      source "stagemonitor_env.sh.erb"
      owner  "tomcat"
      group  "tomcat"
      mode   "0755"
      notifies :restart, "service[activtomcat]"
    end
  end
end
