name		 "prom-elasticsearch"
maintainer       "Bryan Phinney"
maintainer_email "bryan.phinney@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures promethean elasticsearch components"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.3"
%w{java yum prom-default prom-nrpe prom-collectd prom-newrelic}.each do |cookbook|
  depends cookbook
end
