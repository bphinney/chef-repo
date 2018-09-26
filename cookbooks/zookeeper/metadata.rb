name             'zookeeper'
maintainer       'Promethean, Inc'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures zookeeper'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{hostsfile nrpe promaws prom-presearch prom-default}.each do |cookbook|
  depends cookbook
end
