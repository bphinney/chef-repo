name		 "prom-collabserver"
maintainer       "Bryan Phinney"
maintainer_email "bryan.phinney@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures Promethean Backend Collabserver"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.3"
%w{java prom-default prom-presearch prom-activtomcat}.each do |cookbook|
  depends cookbook
end
