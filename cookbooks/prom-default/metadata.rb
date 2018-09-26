name             'prom-default'
maintainer       'Promethean, Inc.'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-default'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.1'
%w{aws yum prom-presearch prom-nrpe promaws hostsfile}.each do |cookbook|
  depends cookbook
end
