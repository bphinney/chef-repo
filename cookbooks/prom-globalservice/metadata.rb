name             'prom-globalservice'
maintainer       'Promethean DevOps'
maintainer_email 'devops@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-globalservice'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{prom-default prom-nrpe prom-presearch prom-activtomcat}.each do |cookbook|
  depends cookbook
end
