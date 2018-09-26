name             'prom-parentservice'
maintainer       'Promethean DevOps'
maintainer_email 'devops@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-parentservice'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.4'
%w{prom-default prom-nrpe prom-presearch prom-activtomcat}.each do |cookbook|
  depends cookbook
end
