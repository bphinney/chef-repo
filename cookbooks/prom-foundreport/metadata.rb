name             'prom-foundreport'
maintainer       'Bryan Phinney'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures Foundation-Report'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{java yum promaws prom-default prom-nrpe prom-presearch prom-newrelic prom-activfoundation}.each do |cookbook|
  depends cookbook
end
