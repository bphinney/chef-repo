name             'prom-classfront'
maintainer       'Promethean, Inc.'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-classfront'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{prom-default prom-http promaws prom-presearch dotcms}.each do |cookbook|
  depends cookbook
end
