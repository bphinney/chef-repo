name             'prom-local'
maintainer       'Promethean, Inc'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-local'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{zookeeper}.each do |cookbook|
  depends cookbook
end
