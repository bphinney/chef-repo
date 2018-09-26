# -----------------------------------------
#   Single Item update: Default .htaccess
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

if node.chef_environment.include?("local")
  node.default['apache']['allow_external'] = "true"
end

if node['platform_version'].to_i == "7" && node['apache']['allow_external'] == "true"
  allow_external = "Require all granted"
  file_check = "granted"
elsif node['platform_version'].to_i == "7" && node['apache']['allow_external'] == "false"
  allow_external = "Require all denied"
  file_check = "denied"
elsif node['apache']['allow_external'] == "true"
  allow_external = "Allow from all"
  file_check = "Allow"
elsif node['apache']['allow_external'] == "false"
  allow_external = "Deny from all"
  file_check = "Deny"
end

template "/etc/httpd/conf.d/.htaccess" do
  source "htaccess-default.erb"
  owner  "root"
  owner  "root"
  mode   "0644"
  variables(
      :allow_external =>  allow_external,
      :internalblock=> node['apache']['internal_block'].split(",")
  )
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
  #only_if { ! File.exists?("/etc/httpd/conf.d/.htaccess") }
  not_if "cat /etc/httpd/conf.d/.htaccess | grep #{file_check}"
end

template "/etc/httpd/conf.d/.htaccess_closed" do
  source "htaccess-default.erb"
  owner  "root"
  owner  "root"
  mode   "0644"
  variables(
      :allow_external =>  allow_external,
      :internalblock => node['apache']['internal_block'].split(",")
  )
  notifies :"#{node['apache']['changetype']}", "service[httpd]"
  #only_if { ! File.exists?("/etc/httpd/conf.d/.htaccess") }
  not_if { File.exists?("/etc/httpd/conf.d/.htaccess_closed") }
end

