name             'prom-cloudwatch'
maintainer       'Promethean DevOps'
maintainer_email 'devops@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-cloudwatch'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.1'
%w{ promaws }.each do |cookbook|
  depends cookbook
end
