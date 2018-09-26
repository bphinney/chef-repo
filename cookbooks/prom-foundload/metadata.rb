name		 'prom-foundload'
maintainer       'Bryan Phinney'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures Foundation-Load'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.3'
%w{prom-default prom-activtomcat prom-presearch}.each do |cookbook|
  depends cookbook
end
