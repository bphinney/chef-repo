#
# Cookbook Name:: atlassian
# Recipe:: ubuntu-build
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#

%w{build-essential git libc6-i386 mtd-utils uboot-mkimage filters openjdk-7-jdk openjdk-8-jdk}.each do |package|
  package package do
    :upgrade
  end
end

group 'bamboo' do
  gid '1001'
  action :create
  not_if { node['etc']['group']['bamboo'] }
end

user 'bamboo' do
  uid '1001'
  gid '1001'
  home '/opt/bamboo-agent-home'
  shell '/bin/bash'
  action :create
  not_if { node['etc']['passwd']['bamboo'] }
end

# Setup git to rebase by default
execute "git-rebase-always" do
  command "su - -c 'git config --global pull.rebase true; git config --global branch.autosetuprebase always' bamboo"
  action :run
  not_if "su - -c 'git config --get branch.autosetuprebase' bamboo | grep always"
end

directory "/opt/bamboo" do
  action :create
end

execute "change_ownership" do
  command "chown -R bamboo:bamboo /opt/bamboo-agent-home"
  action :nothing
end

execute "bamboo_agent_install" do
  command "cd /opt/bamboo; java -jar atlassian-bamboo-agent-installer-*.jar install -Dbamboo.home=/opt/bamboo-agent-home https://bamboo.prometheanjira.com"
  action :nothing
  notifies :run, "execute[change_ownership]"
end

remote_file "/opt/bamboo/atlassian-bamboo-agent-installer-5.10.2.jar" do
  source "https://bamboo.prometheanjira.com/agentServer/agentInstaller/atlassian-bamboo-agent-installer-5.10.2.jar"
  owner  "root"
  group  "root"
  action :create_if_missing
  notifies :run, "execute[bamboo_agent_install]"
end

#execute "systemctl_reload" do
#  command "systemctl daemon-reload"
#  action :nothing
#end

#template "/etc/systemd/system/bamboo-agent.service" do
#  source "bamboo-agent.service.erb"
#  owner  "root"
#  group  "root"
#  notifies :run, "execute[systemctl_reload]"
#end

template "/etc/init.d/bamboo-agent" do
  source "bamboo-agent-ubuntu.erb"
  owner  "root"
  group  "root"
  mode   "0755"
end

service "bamboo-agent" do
  supports :start => true, :stop => true, :restart => true
  #start_command "systemctl bamboo-agent start"
  #stop_command "systemctl bamboo-agent stop"
  #restart_command "systemctl bamboo-agent restart"
  action [:start, :enable]
end

## ActivDriver Linux Dependencies for Ubuntu (CI-74) ##
# build-essential, git, libc6-i386 provided above

# qmake dependency installation
#execute 'Qt4_Install' do
#  command 'apt-get build-dep -y qt4-qmake'
#  action :run
#end
# Qmake dependency installation replaced by install the specific dependencies by name
%w{libc6 libgcc1 libstdc++6}.each do |package|
  package package do
    action :upgrade
  end
end

%w{libfam-dev zlib-bin}.each do |package|
  package package do
    action :upgrade
  end
end

# 32-bit dependencies (Possibly 14.04 only)
# Removed libudev-dev as the i386 version can not be installed with it
%w{libc6-dev-i386 libudev-dev:i386}.each do |package|
  package package do
    action :upgrade
  end
end

# install kernel header and source dependencies
%w{linux-headers-generic linux-source}.each do |package|
  package package do
    action :upgrade
  end
end

# link libudev (Possibly 14.04 only)
link '/lib/i386-linux-gnu/libudev.so.1' do
  to '/usr/lib/i386-linux-gnu/libudev.so'
  action :create
  only_if 'test -f /usr/lib/i386-linux-gnu/libudev.so'
end

## End ActivDriver Linux Dependencies ##

# Install s3cmd for pushing files to Amazon S3
package "s3cmd" do
  action :upgrade
end

## Scripts  ##
cookbook_file "/opt/bamboo-agent-home/bin/update-repo" do
  source "update-repo"
  owner  "bamboo"
  group  "bamboo"
  mode   "0775"
end

cookbook_file "/opt/bamboo-agent-home/bin/while-sync.sh" do
  source "while-sync.sh"
  owner  "bamboo"
  group  "bamboo"
  mode   "0775"
end

cookbook_file "/usr/local/bin/zidoo-build" do
  source "zidoo-build"
  owner  "root"
  group  "root"
  mode   "0775"
end

# Pull aws credentials from data bag
awscreds = data_bag_item("aws-sdk", "s3cfg")
template "/opt/bamboo-agent-home/.s3cfg" do
  source "s3cfg.erb"
  owner  "bamboo"
  group  "bamboo"
  mode   "0600"
  variables(
    :aws_access_key_id => awscreds['aws_access_key_id'],
    :aws_secret_access_key => awscreds['aws_secret_access_key']
  )
end

cookbook_file "/usr/local/bin/zidoo-image-package" do
  source "zidoo-image-package"
  owner  "root"
  group  "root"
  mode   "0775"
end

cookbook_file "/usr/local/bin/zidoo-check-version" do
  source "zidoo-check-version"
  owner  "root"
  group  "root"
  mode   "0775"
end
