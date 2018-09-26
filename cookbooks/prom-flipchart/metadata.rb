name		 'prom-flipchart'
maintainer       'Bryan Phinney'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures Flipchart'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.3'
%w{promaws prom-default prom-activtomcat prom-activfoundation prom-presearch glusterfs}.each do |cookbook|
  depends cookbook
end
