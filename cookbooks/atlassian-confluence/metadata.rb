name		 "atlassian-confluence"
maintainer       "Promethean"
maintainer_email "devops@prometheanworld.com"
license          "All rights reserved"
description      "Installs/Configures atlassian"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"
%w{ atlassian java prom-default }.each do |cookbook|
  depends cookbook
end
