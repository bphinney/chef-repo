name             'prom-logback'
maintainer       'Promethean, Inc'
maintainer_email 'william.whitlark@prometheanworld.com'
license          'All rights reserved'
description      'Provildes logging-backend script to backend servers.'
long_description 'Provildes logging-backend script to backend servers.'
version          '0.0.1'

%w{prom-activfoundation prom-foundasync prom-foundload prom-fmaint prom-collabserver prom-foundetl prom-globalservice prom-parentservice prom-flipchart prom-authserver}.each do |cookbook|
  depends cookbook
end
