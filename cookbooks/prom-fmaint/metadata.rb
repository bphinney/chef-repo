name		 "prom-fmaint"
maintainer       "Promethean DevOps"
maintainer_email "devops@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures foundation maintenance"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
%w{prom-default prom-presearch prom-activtomcat}.each do |cookbook|
  depends cookbook
end
