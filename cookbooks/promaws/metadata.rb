name             'promaws'
maintainer       'Promethean Inc.'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Supports additional features beyond aws community cookbook'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
#depends 'aws', '<= 2.9.2'
%w{prom-default aws}.each do |cookbook|
  depends cookbook
end
