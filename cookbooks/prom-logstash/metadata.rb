name		 "prom-logstash"
maintainer       "Promethean DevOps"
maintainer_email "devops@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures logstash applications"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
%w{java prom-default prom-http promaws}.each do |cookbook|
  depends cookbook
end

