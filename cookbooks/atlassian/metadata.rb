name		 "atlassian"
maintainer       "Promethean"
maintainer_email "bryan.phinney@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures atlassian"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.3"
%w{iptables hostsfile haproxy yum prom-default promaws prom-presearch prom-http line omnibus_updater java}.each do |cookbook|
  depends cookbook
end
