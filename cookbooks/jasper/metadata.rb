name             'jasper'
maintainer       'Promethean, Inc.'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures jasper'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{java prom-default}.each do |cookbook|
  depends cookbook
end
