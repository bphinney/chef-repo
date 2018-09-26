name             'android_ota'
maintainer       'Promethean, Inc'
maintainer_email 'bryan.phinney@prometheanworld.com'
license          'All rights reserved'
description      'Installs/Configures Android Over-The-Air Update Server for Android ActivConnect'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'mysql', '~> 6.0'
depends 'promaws'
depends 'prom-default'
depends 'onddo_proftpd'
depends 'yum'

