name             'prom-provisioner'
maintainer       'Promethean, Inc.'
maintainer_email 'bryan.phinney@prometehanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-provisioner'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{prom-default prom-chef prom-activtomcat yum}.each do |cookbook|
  depends cookbook
end
