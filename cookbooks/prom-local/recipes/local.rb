#
# Cookbook Name:: prom-local
# Recipe:: local
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

$tenants = search(:foundation, "env:#{node.chef_environment}")
$tenants.each do |tenant|
  if tenant["tenant_config.is_default_tenant"] == "\u0001"
      $tenant_name = tenant["tenant_config.tenant_name"]
      $host_url = tenant["tenant_config.host_url"]
      $teacher_url = tenant["tenant_config.teacher_workspace_url"]
      $collabserver_url = tenant["tenant_config.collabserver_url"]
  end
end

if node['platform_version'] < '7'
  template "/etc/inittab" do
    source "inittab-local.erb"
    owner "root"
    group "root"
    mode "0644"
  end
else
  link '/etc/systemd/system/default.target' do
    to '/usr/lib/systemd/system/multi-user.target'
    action :create
  end
end

execute "db_setup" do
  command "/usr/bin/db-setup"
  action :nothing
end

template "/usr/bin/db-setup" do
  source "db-setup.erb"
  mode  "0755"
  owner "root"
  group "root"
  variables(:tenantname => $tenant_name,
    :tenant_header => $tenant_header,
    :hosturl => $host_url,
    :teacherurl => $teacher_url,
    :collabserverurl => $collabserver_url
  )
  notifies :run, "execute[db_setup]"
end

# Build the /usr/bin/import_tenant_data.sh from the env and tenant record details.
template "/usr/bin/import_tenant_data.sh" do
  source "import_tenant_data.sh.erb"
  user   "root"
  group  "root"
  mode   0777
  variables(
    :dbservername => node['database']['dbservername'],
    :activfoundbuser => node['af']['activfoundbuser'],
    :activfoundbpass => node['af']['activfoundbpass'],
    :datasource_id => "0a75ac09c7a14f949e02ee8a445d14f0",
    :tenant_id => "a010f8cda6be452a95678785478c3360",
    :tenant_name => $tenant_name,
    :activfoundb => node['af']['activfoundb'],
    :founconfigdb => node['fconfig']['founconfigdb'],
    :host_url => $host_url,
    :teacher_ur => $teacher_url,
    :collabserver_url => $collabserver_url,
    :import_env => node.chef_environment,
    :export_env => node['dataexportenv']
  )
end

template "/usr/bin/local-deploy" do
  source "local-deploy.erb"
  mode   "00755"
  owner  "root"
  group  "root"
end

template "/usr/bin/remote-deploy" do
  source "remote-deploy.erb"
  mode   "00755"
  owner  "root"
  group  "root"
end

file "/etc/localtime" do
  action :delete
  not_if "test -L /etc/localtime"
end
# Set timezone to UTC on all vagrant instances
link "/etc/localtime" do
  to "/usr/share/zoneinfo/UTC"
end

# Drops schemas and calls db-setup to restore schemas
template "/usr/bin/reset-db" do
  source "reset-db.erb"
  mode  "0755"
  owner "root"
  group "root"
  variables(
    :reset => "true"
  )
end

# reset-db script without the db-setup step
template "/usr/bin/clear-db" do
  source "reset-db.erb"
  mode  "0755"
  owner "root"
  group "root"
end

# reset-db script without the db-setup step
template "/usr/bin/db-backup" do
  source "db-backup.erb"
  mode  "0755"
  owner "root"
  group "root"
end

# reset-db script without the db-setup step
template "/usr/bin/db-restore" do
  source "db-restore.erb"
  mode  "0755"
  owner "root"
  group "root"
end

template "/usr/bin/reset-af-db" do
  source "reset-af-db.erb"
  mode   "0755"
  owner  "root"
  group  "root"
end

template "/usr/bin/es-reset" do
  source "es-reset.erb"
  mode   "0755"
  owner  "root"
  group  "root"
end

template "/usr/bin/es-clean" do
  source "es-clean.erb"
  mode   "0755"
  owner  "root"
  group  "root"
end

template "/usr/bin/clear_lb_locks" do
  source "clear_lb_locks.erb"
  mode   "0755"
  owner  "root"
  group  "root"
end

template "/usr/bin/log-clear" do
  source "log-clear.erb"
  mode   "0755"
  owner  "root"
  group  "root"
end

cookbook_file "/usr/bin/kill-rabbitmq" do
  source "kill-rabbitmq"
  mode  "0755"
  owner "root"
  group "root"
end

# Requirements for UI-Admin in local Env
directory "/usr/local/bin/uiadmin" do
  owner "root"
  group "root"
  mode  "0755"
  action :create 
end

template "/usr/local/bin/demo-db-setup" do
  source "demo-db-setup.erb"
  mode   "0755"
  owner  "root"
  group  "root"
  only_if { node.chef_environment.include?("demo") }
end

%w{person.csv user.csv user_role.csv user_permission.csv}.each do |file|
  cookbook_file "/usr/local/bin/uiadmin/#{file}" do
    source "uiadmin_#{file}"
    owner  "root"
    group  "root"
    mode   "0755"
  end
end

include_recipe "prom-local::redis"
include_recipe "zookeeper::remove"
