name		 "prom-chef"
maintainer       "DevOps"
maintainer_email "devops@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures promethean chef server."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
depends 'mysql', '~> 6.0'
%w{dotcms haproxy iptables prom-default prom-iptables prom-presearch promaws}.each do |cookbook|
  depends cookbook
end
