name             'prom-metrics'
maintainer       'Promethean, Inc.'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures metrics-server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{prom-default yum java python aws prom-presearch prom-collectd}.each do |cookbook|
  depends cookbook
end
