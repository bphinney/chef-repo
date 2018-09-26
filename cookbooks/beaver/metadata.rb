name             'beaver'
maintainer       'rsavage'
maintainer_email 'rory.savage@prometheanworld.com'
license          'Apache 2.0'
description      'Installs/Configures beaver'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.0'
recipe           'beaver', 'Installs and configures beaver to ship logs to logstash'
%w{ python }.each do |cookbook|
  depends cookbook
end

%w{ centos }.each do |os|
  supports os
end
