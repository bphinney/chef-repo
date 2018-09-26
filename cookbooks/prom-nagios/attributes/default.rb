override['nagios']['cgi-path'] = "/cgi-bin/nagios/"
default['nagios']['server']['install_method'] = "package"
#override['nagios']['cgi-bin'] = "/usr/lib64/nagios/cgi-bin"
default['nagios']['regexp_matching'] = "0"
default['nagios']['nomonitoring'] = [ "_default", "poc", "local", "localdemo", "localappliance", "localchina", "localvalidate", "cent7", "loadtest", "loadtest2" ]
