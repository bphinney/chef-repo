name             'prom-nagios'
maintainer       'Promethean, Inc.'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-nagios'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{promaws prom-default prom-presearch prom-mailrelay prom-http}.each do |cookbook|
  depends cookbook
end

