#
# Cookbook Name:: prom-chef
# Recipe:: hardening
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#

include_recipe "prom-default"

# Security Hardening Section
if node["hardening"]["haproxyservice"] == "disabled"
  yum_package "haproxy" do
    action :remove
  end
elsif node["hardening"]["haproxyservice"] == "enabled"
  include_recipe "haproxy::default"
  service "haproxy" do
    supports :start => true, :restart => true, :stop => true, :status => true, :reload => true
    action :nothing
  end
  template "/etc/haproxy/haproxy.cfg" do
    source "bamboo_proxy.erb"
    owner  "root"
    group  "root"
    mode   "0640"
    notifies :reload, "service[haproxy]"
  end
end

ruby_block "disable-rsync-cmd" do
  block do
    ::File.rename "/usr/bin/rsync", "/usr/bin/rsync.LOCKED"
    ::File.chmod(0000, "/usr/bin/rsync.LOCKED")
  end
  only_if { node["hardening"]["rsyncaccess"] == "disabled" and File.exists?('/usr/bin/rsync') }
end

# IN-955
if node["hardening"]["tar"] == "disabled"
  ruby_block "disable-tar-cmd" do
    block do
      ::File.rename "/bin/tar", "/bin/tar.LOCKED"
      ::File.chmod(0000, "/bin/tar.LOCKED")
    end
      only_if { node["hardening"]["tar"] == "disabled" and File.exists?('/bin/tar') }
    end
end

if node["hardening"]["zip"] == "disabled"
  ruby_block "disable-zip-cmd" do
    block do
      ::File.rename "/usr/bin/zip", "/usr/bin/zip.LOCKED"
      ::File.chmod(0000, "/usr/bin/zip.LOCKED")
    end
      only_if { node["hardening"]["zip"] == "disabled" and File.exists?('/usr/bin/zip') }
    end
end
#

if node["hardening"]["sftpaccess"] == "disabled"
  ruby_block "disable-sftp-service" do
    block do
      rc = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
      rc.search_file_replace_line(
      "Subsystem	sftp	/usr/libexec/openssh/sftp-server",
      "#Subsystem        sftp    /usr/libexec/openssh/sftp-server"
      )
      rc.write_file
    end
  end
  ruby_block "disable-sftp-cmd" do
    block do
      ::File.rename "/usr/bin/sftp", "/usr/bin/sftp.LOCKED"
      ::File.chmod(0000, "/usr/bin/sftp.LOCKED")
    end
    only_if { File.exists?('/usr/bin/sftp') }
  end
end

if node["hardening"]["scpaccess"] == "disabled"
  ruby_block "disable-scp-cmd" do
    block do
      ::File.rename "/usr/bin/scp", "/usr/bin/scp.LOCKED"
      ::File.chmod(0000, "/usr/bin/scp.LOCKED")
    end
      only_if { node["hardening"]["scpaccess"] == "disabled" and File.exists?('/usr/bin/scp') }
    end
end

yum_package "ftp" do
  action :remove
  only_if { node["hardening"]["ftpaccess"] == "disabled" }
end

if node["hardening"]["remoteroot"] == "disabled"
  ruby_block "disable-remote-root" do
    block do
      rc = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
      rc.search_file_replace_line(
      "PermitRootLogin without-password",
      "PermitRootLogin no"
      )
      rc.write_file
    end
  end
end

if node["hardening"]["emailreports"] == "enable"
  if node.attribute?('hostname') && node.attribute?('aws') && node['aws'].attribute?('region')
    emailsubject="Daily Security Digest: #{node['hostname']}@#{node['aws']['region']}"
  else
    emailsubject="Daily security digest: [chef-server]"
  end
  emailaddress="ops.classflow@prometheanworld.com"
  yum_package "logwatch" do
    action :install
  end
  template "/etc/logwatch/conf/logwatch.conf" do
    source "logwatch.conf.erb"
    owner  "root"
    group  "root"
    mode   "0640"
  end
  template "/usr/share/logwatch/default.conf/services/zz-disk_space.conf" do
    source "zz-disk_space.conf.erb"
    owner  "root"
    group  "root"
    mode   "0640"
  end
  cron "emailreports" do
    command "/usr/sbin/logwatch --print --detail 15 | mail -s '#{emailsubject}' #{emailaddress}"
    hour "0"
    minute "0"
    action :create
  end
end

execute "sshd_restart" do
  command "service sshd restart"
  action :nothing
end

# Turn off password authentication in SSHD
template "/etc/ssh/sshd_config" do
  if node['hardening']['sshd'] == "enable"
    source "sshd_config_hardened.erb"
  else
    source "sshd_config_normal.erb"
  end
  notifies :run, "execute[sshd_restart]"
end

if node["hardening"]["localfirewall"] == "enable"
#  include_recipe "iptables::default"
  include_recipe "prom-iptables::chefserver"
#  %w{port_sshd port_postfix port_souschef port_chefserver}.each do |port|
#    iptables_rule port
#  end
#  service "iptables" do
#    supports :stop => true, :start => true, :restart => true, :reload => true, :status => true, :enable => true
#    action [:start, :enable]
#  end
end

if node["hardening"]["sshtunnels"] == "disable"
  ruby_block "disable-tcp-forwarding" do
    block do
      rc = Chef::Util::FileEdit.new("/etc/ssh/sshd_config")
      rc.search_file_replace_line(
      "#AllowTcpForwarding yes",
      "AllowTcpForwarding no"
      )
      rc.write_file
    end
  end
end
