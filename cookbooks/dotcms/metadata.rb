name		 "dotcms"
maintainer       "DevOps"
maintainer_email "devops@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures dotcms applications."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
%w{java promaws prom-default prom-presearch prom-nrpe}.each do |cookbook|
  depends cookbook
end
