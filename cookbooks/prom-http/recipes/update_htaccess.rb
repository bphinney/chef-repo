# -----------------------------------------
#   Single Item update: Tenants .htaccess
# -----------------------------------------

service "httpd" do
  if node['platform_version'].to_i == '7'
    stop_command "/usr/bin/systemctl stop httpd"
    start_command "/usr/bin/systemctl start httpd"
    reload_command "/usr/sbin/apachectl reload"
    restart_command "/usr/bin/systemctl restart httpd"
  else
    stop_command  "/etc/init.d/httpd stop"
    start_command "/etc/init.d/httpd start"
    reload_command "/etc/init.d/httpd graceful"
    restart_command "/etc/init.d/httpd restart"
  end
  supports :stop => true, :start => true, :restart => true, :status => true, :reload => true, :graceful => true
  action :nothing
end

$env          = node.chef_environment
$whitelist_ip = data_bag_item('apache', 'whitelist')
$blacklist_ip = data_bag_item('apache', 'blacklist')

if node['platform_version'].to_i == "7" && node['apache']['allow_external'] == "true"
  allow_external = "Require all granted"
elsif node['platform_version'].to_i == "7" && node['apache']['allow_external'] == "false"
  allow_external = "Require all denied"
elsif node['apache']['allow_external'] == "true"
  allow_external = "Allow from all"
elsif node['apache']['allow_external'] == "false"
  allow_external = "Deny from all"
end

internal_block = node['apache']['internal_block']
template "/etc/httpd/conf.d/.htaccess" do
  source "htaccess.erb"
  owner  "root"
  owner  "root"
  mode   "0644"
  variables(
      :countryblock => node['countryblock'].split(","),
      :whitelist_ip => $whitelist_ip,
      :blacklist_ip => $blacklist_ip,
      :allow_external =>  allow_external,
      :internalblock => node['apache']['internal_block'].split(",")
  )
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
  only_if "test -d /etc/httpd/conf.d"
end

# Setup Alternate htaccess file for restricted functions
if node['platform_version'].to_i == "7"
  deny_external = "Require all denied"
else
  deny_external = "Deny from all"
end
template "/etc/httpd/conf.d/.htaccess_closed" do
  source "htaccess_closed.erb"
  owner  "root"
  owner  "root"
  mode   "0644"
  variables(
      :countryblock => node['countryblock'].split(","),
      :whitelist_ip => $whitelist_ip,
      :blacklist_ip => $blacklist_ip,
      :deny_external =>  deny_external,
      :internalblock => node['apache']['internal_block'].split(",")
  )
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
  only_if "test -d /etc/httpd/conf.d"
end

# Setup Alternate dotcmsaccess file for restricted functions
if node['platform_version'].to_i == "7"
  deny_external = "Require all denied"
else
  deny_external = "Deny from all"
end
template "/etc/httpd/conf.d/.dotcmsaccess" do
  source "dotcmsaccess.erb"
  owner  "root"
  owner  "root"
  mode   "0644"
  variables(
      :countryblock => node['countryblock'].split(","),
      :whitelist_ip => $whitelist_ip,
      :blacklist_ip => $blacklist_ip,
      :deny_external =>  deny_external,
      :internalblock => node['apache']['internal_block'].split(",")
  )
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
  only_if "test -d /etc/httpd/conf.d"
end
                                            
