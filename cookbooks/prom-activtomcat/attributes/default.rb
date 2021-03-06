# Java Defaults NEW
default["java"]["java_xms_memory"] = "1024M"
default["java"]["java_xmx_memory"] = "2048M"
default["java"]["java_max_perm"] = "512M"
default["java"]["jmx_console_enable"] = "false"
default["java"]["truststore"] = "false"
default["java"]["user_name"] = "tomcat"
default["java"]["user_uid"] = "495"
default["java"]["user_gid"] = "496"
default["java"]["threadpool"] = "150"
default["java"]["niothreadpool"] = "400"
default["java"]["ajpthreadpool"] = "400"
default["java"]["samlkeystore"] = "false"
default["java"]["samlkeystorepass"] = "Promethean1"
default["java"]["samlkeystorepath"] = "/opt/tomcat/security/samlKeystore.jks"
default["java"]["samlkeystorepathname"] = "/opt/tomcat/security"
default["java"]["samlkeystorefile"] = "samlKeystore.jks"
default["java"]["samlrefreshdelay"] = "300000"
default['java']['jdk_version'] = "8"
default["java"]["crawlerlist"] = ".*haproxy.*|.*NewRelicPinger.*|.*mon\.itor\.us.*|.*monitis.*|.*alertsite.*|.*uptimerobot.*|.*statuscake.*|.*googlebot.\*|.*yahoo.*|.*ELB-Heathchecker.*"
# Tomcat Defaults
default['tomcat']['jarstoskip'] = nil
default['tomcat']['Tldjarstoskip'] = nil
default['tomcat']['version'] = "8.0.23-1"
default['tomcat']['logback'] = "true"
default['tomcat']['filenumber'] = "100000"
default['tomcat']['filesize'] = "unlimited"
default['tomcat']['procnumber'] = "2048"
default['tomcat']['sessions'] = "stateful"
