package 'iptables' do
  action :install
end

cookbook_file '/etc/firewall.sh' do
  mode '0755'
end

cookbook_file '/etc/firewall.conf' do
	not_if { ::File.exists?("/etc/firewall.conf") }
end

file '/etc/firewall.chef' do
	content ''
    owner 'root'
    group 'root'
    mode '0644'
	not_if { ::File.exists?("/etc/firewall.chef") }
end

execute 'activate firewall' do
  command 'sh /etc/firewall.sh'
end

link '/etc/init.d/firewall' do
  to '/etc/firewall.sh'
end
