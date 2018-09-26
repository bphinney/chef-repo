#
# Cookbook Name:: promethean
# Recipe:: collab_sysctl
#
# Copyright 2013, Promethean
#
# All rights reserved - Do Not Redistribute
#

execute "sysctl_reload" do
  command "sysctl -p"
  returns [0,255]
  action :nothing
end

removals = ['fs.file-max = 100000', 'fs.nr_open = 100000']
removals.each do |removal|
  delete_lines removal do
    path "/etc/sysctl.conf"
    pattern "#{removal}"
  end
end

entries = ['net.ipv4.tcp_tw_reuse = 1','net.ipv4.ip_local_port_range = 1024 65023','net.ipv4.tcp_max_syn_backlog = 10240','net.ipv4.tcp_max_tw_buckets = 400000','net.ipv4.tcp_max_orphans = 60000','net.ipv4.tcp_synack_retries = 3','net.core.somaxconn = 10000','net.ipv4.tcp_tw_reuse = 1', 'fs.file-max = 400000', 'fs.nr_open = 400000']
entries.each do |entry|
  append_if_no_line entry do
    path "/etc/sysctl.conf"
    line entry
    notifies :run, "execute[sysctl_reload]"
  end
end
