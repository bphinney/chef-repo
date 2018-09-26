name             'prom-authserver'
maintainer       'Bryan Phinney'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-authserver'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{prom-default prom-nrpe prom-presearch prom-activtomcat glusterfs}.each do |cookbook|
  depends cookbook
end
