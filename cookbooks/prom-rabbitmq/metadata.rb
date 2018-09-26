name             'prom-rabbitmq'
maintainer       'Bryan Phinney'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures prom-rabbit RabbitMQ Instances'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
%w{promaws prom-default prom-nrpe prom-presearch prom-newrelic}.each do |cookbook|
  depends cookbook
end
