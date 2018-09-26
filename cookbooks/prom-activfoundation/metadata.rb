name             'prom-activfoundation'
maintainer       'Promethean, Inc'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-activfoundation'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.1'

%w{glusterfs prom-activtomcat prom-default}.each do |cookbook|
  depends cookbook
end
