#
# Cookbook Name:: atlassian
# Recipe:: centos-build
#
# Copyright 2012, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Development Tools
%w{bison wget bc byacc cscope ctags cvs diffstat doxygen flex gcc gcc-c++ gcc-gfortran gettext git indent intltool libtool patch patchutils rcs redhat-rpm-config rpm-build subversion swig systemtap}.each do |package|
  yum_package package do
    action :upgrade
  end
end

# Java installation
%w{java-1.7.0-openjdk java-1.7.0-openjdk-devel java-1.8.0-openjdk java-1.8.0-openjdk-devel}.each do |package|
  yum_package package do
    action :upgrade
  end
end

#s3cmd direct download and install
execute "s3cmd-wget" do
  command " cd /opt; wget -O s3dir.tar.gz http://downloads.sourceforge.net/project/s3tools/s3cmd/1.6.1/s3cmd-1.6.1.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fs3tools%2Ffiles%2Fs3cmd%2F1.6.1%2F&ts=1464801981&use_mirror=internode"
action :run
not_if 'test -f /opt/s3dir*'
end

execute "gzip-s3cmd" do
 command "cd /opt; tar xzf s3dir.tar.gz"
 action :run
 not_if 'test -d /opt/s3cmd*'
end 

execute "s3cmd-pyinstall" do
  command "cd /opt/s3dir*; python setup.py install"
  action :run
  not_if 'test -f /usr/bin/s3cmd'
end

# Additional dependencies
%w{gnupg flex gperf zip curl zlib-devel glibc.i686 glibc-devel.i686 libstdc++.i686 zlib-devel.i686 ncurses-devel.i686 libX11-devel.i686 libXrender.i686 libXrandr.i686 }.each do |package|
  yum_package package do
    action :upgrade
  end
end  

#ARM Dependency

directory "/opt/zidoo-x6-pro" do
  action :create
end

execute "change_ownership" do
  command "chown -R bamboo:bamboo /opt/zidoo-x6-pro"
  action :nothing
end

execute "zidoos3dl" do
  command "cd /opt/zidoo-x6-pro; wget http://s3.amazonaws.com/zidoo1/zidoo.tar.gz"
  action :run
 not_if 'test -f /opt/zidoo-x6-pro/zidoo.tar.gz'
end

execute "gzip-zidootar" do
  command "cd /opt/zidoo-x6-pro/; tar xzf zidoo.tar.gz"
  action :run
  not_if 'test -d /opt/zidoo-x6-pro/u-boot'
end

execute "arm-install" do
  command "mv /opt/arm*.tar.gz /usr/local/; chmod 777 /usr/local/arm*.tar.gz; cd /usr/local; tar zxvf arm*.tar.gz"
  action :nothing
end

remote_file "/opt/arm-2012.09.tar.gz" do
  source "https://yumrepo.prometheanjira.com/core/arm-2012.09.tar.gz"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :run, "execute[arm-install]", :immediately
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
  owner "bamboo"
  group "bamboo"
end
      
#Setup bamboo agent
%w{bamboo bamboo-agent-home}.each do |directory|
  directory directory do
    action :create
    owner "bamboo"
    group "bamboo"
  end
end

execute "change_ownership" do
  command "chown -R bamboo:bamboo /opt/bamboo-agent-home"
  action :nothing
end

remote_file "/opt/bamboo/atlassian-bamboo-agent-installer-5.10.2.jar" do
  source "https://bamboo.prometheanjira.com/agentServer/agentInstaller/atlassian-bamboo-agent-installer-5.10.2.jar"
  owner  "root"
  group  "root"
  action :create_if_missing
  notifies :run, "execute[bamboo_agent_install]", :immediately
end

execute "bamboo_agent_install" do
  command "cd /opt/bamboo; java -Dbamboo.home=/opt/bamboo-agent-home/ -jar atlassian-bamboo-agent-installer-5.10.2.jar https://bamboo.prometheanjira.com/agentServer/"
  action :nothing
  notifies :run, "execute[change_ownership]"
end

if node['platform_version'].to_i == '7'
  execute "systemctl_reload" do
    command "systemctl daemon-reload"
    action :nothing
  end

  template "/etc/systemd/system/bamboo-agent.service" do
    source "centos-bamboo-service.erb"
    owner  "root"
    group  "root"
    notifies :run, "execute[systemctl_reload]"
  end
elsif node['platform_version'].to_i == '6'
  template "/etc/init.d/bamboo-agent" do
    source "bamboo-agent-ubuntu.erb"
    owner  "root"
    group  "root"
    mode   "0755"
  end
end

directory "/opt/bamboo-agent-home/.ssh" do
  action :create
  mode  "0600"
  owner "bamboo"
  group "bamboo"
end

cookbook_file "/opt/bamboo-agent-home/.ssh/id_rsa" do
  source "zidoo-key"
  owner "bamboo"
  group "bamboo"
  mode  "0600"
end

#Google Repo
directory "/opt/bamboo-agent-home/bin" do
  action :create
end

remote_file "/opt/bamboo-agent-home/bin/repo" do
  source "https://storage.googleapis.com/git-repo-downloads/repo"
  owner  "bamboo"
  group  "bamboo"
  action :create_if_missing
end

# Pull aws credentials from data bag
awscreds = data_bag_item("aws-sdk", "s3cfg")
template "opt/bamboo-agent-home/.s3cfg" do
  source "s3cfg.erb"
  owner "bamboo"
  group "bamboo"
  mode "0600"
 variables(
   :aws_access_key_id => awscreds['aws_access_key_id'],
   :aws_secret_access_key => awscreds['aws_secret_access_key']
  )
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

cookbook_file "/usr/local/bin/zidoo-centos-build" do
  source "zidoo-centos-build"
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

cookbook_file "/usr/local/bin/centos-image-package" do
  source "centos-image-package"
  owner  "root"
  group  "root" 
  mode   "0775"
end 
