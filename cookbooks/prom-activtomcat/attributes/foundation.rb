# Chef attributes
default["chefclient_daemon"] =  "false"
default['chef_server']['environment'] = "USA - Dev/QA"
default['chef']['allow_insecure'] = "false"
default['chef']['release_list'] = "ram.venkataraman@prometheanworld.com ahmad.aslami@prometheanworld.com william.baleson@prometheanworld.com jennifer.jones@prometheanworld.com steven.gerald@prometheanworld.com andrew.burtnett@prometheanworld.com carlos.londono@prometheanworld.com devops@prometheanproduct.com"
default['chef']['datacenter'] = "QA/Dev Region"
# Machine data
default["provider"] = "local"
# Activfoundation Attributes
default["af"]["activfoundb"] = "activfoundationdev"
default["af"]["activfoundbuser"] = "activplatuser"
default["af"]["activfoundbpass"] = "activplatpass"
default["af"]["activfoundation_internal_url"] = "http://localhost:8080/activfoundation"
default["af"]["elasticrole"] = "elasticsearch"
default["af"]["sessioncleanup"] = ""
default["af"]["freesitedrive"] = "My ClassFlow.Com Drive"
default["af"]["resourcesizelimit"] = "104857600"
default["af"]["netchecktimeout"] = "2000"
default["af"]["sockjsprotocols"] = "iframe-eventsource,iframe-htmlfile,xhr-polling"
default["af"]["youtubesearchurl"] = "https://www.googleapis.com/youtube/v3/search?videoDefinition=standard&order=viewCount&part=snippet&type=video"
default['af']['foundationmaint_log'] = "/opt/tomcat/logs/maint.log"
default['af']['foundationmaint_err'] = "/opt/tomcat/logs/maint.err"
default['af']['foundationmaint_opts'] = "-Dlog.base=/opt/tomcat"
default['af']['elastic_consumers'] = "2"
default['af']['cms_url'] = "https://classflow.com"
default['af']['cms_guid'] = "706242d3-24d1-4149-afa9-03a830ac5c5d"
default['af']['aspose_license'] = "/opt/tomcat/conf/Aspose.Total.Product.Family.lic"
default['af']['intercom_enabled'] = "false"
default['af']['intercom_app_id'] = "l96vyzq2"
default['af']['intercom_api_key'] = "d2525ccda4ef78bdef1802decbebdd46f41a9e35"
default['af']['intercom_secret_key'] = "Lgfe25N_O8GUYoy3hJUGGhEjZ-5i1UoM7sQ8Vt3i"
default['af']['recurly_public_key'] = "sjc-3aL52LOpbQX9GdqagT69NY"
default['af']['recurly_private_key'] = "45d0f4ecf23448ab970e58baeaa95d9c"
default['af']['fastpass_key'] = "o5fg79aix3nq"
default['af']['fastpass_secret'] = "1sccet2g82cs0sljffaa1ogh5w05ihti"
default['af']['fastpass_url'] = "getsatisfaction.com"
default['af']['frame_ancestors'] = "https://*.prometheanjira.com/ http://localhost:8888/ https://classflow.com/ https://*.classflow.com/ https://classflow.co.uk/ https://*.classflow.co.uk/ https://classflow.it/ https://*.classflow.it/ https://classflow.de/ https://*.classflow.de/ https://classflow.se/ https://*.classflow.se/ https://classflow.nl/ https://*.classflow.nl/ https://classflow.lv/ https://*.classflow.lv/ https://classflow.co.au/ https://*.classflow.com.au/ https://classflow.cn/ https://*.classflow.cn/ https://classflow.fr/ https://*.classflow.fr/ https://classflow.at/ https://*.classflow.at/ https://classflow.cz/ https://*.classflow.cz/ https://classflow.ae/ https://*.classflow.ae/ https://classflow.nl/ https://*.classflow.nl/ https://classflow.be/ https://*.classflow.be/ https://classflow.hu/ https://*.classflow.hu/ https://classflow.pt/ https://*.classflow.pt/ https://classflow.pl/ https://*.classflow.pl/ https://classflow.es/ https://*.classflow.es/ https://classflow.lt/ https://*.classflow.lt/ https://classflow.no/ https://*.classflow.no/ https://classflow.dk/ https://*.classflow.dk/ https://classflow.ie/ https://*.classflow.ie/ https://classflow.fi/ https://*.classflow.fi/ https://classflow.et/ https://*.classflow.et/ https://classflow.ua/ https://*.classflow.ua/"
default['af']['performsql'] = "false"
# Default versions
default["applications"]["activfoun_version"] = "0.0.0-1"
# DB defaults
default["database"]["dbserver"] = "prometheandb.cum0ld45s8ef.us-east-1.rds.amazonaws.com:3306"
default["database"]["dbservername"] = "prometheandb.cum0ld45s8ef.us-east-1.rds.amazonaws.com"
default["founconfigdb"] = "fconfigdev"
default["founconfiguser"] = "fconfigdevuser"
default["founconfigpass"] = "fconfigdevpass"
# Default application attributes
default["database"]["contextmode"] = ""
# Default Tenant Defaults
default["collab_url"] = "http://localhost"
default["host_url"] = "http://localhost"
default["tenant_name"] = "localhost"
default["teacher_url"] = "http://localhost"
# AF Debugging Defaults
default["afdebug"]["collabacklog"] = "false"
default["afdebug"]["collabackpersist"] = "false"
default["afdebug"]["sessioninactivate"] = "false"
default["afdebug"]["collabsessioncleanup"] = "false"
default["afdebug"]["socketinactivity"] = "120"
default["afdebug"]["assessmentendtimemonitoring"] = "true"
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
# JDBC Defaults
default["jdbc"]["jdbc_partitioncount"] = "1"
default["jdbc"]["jdbc_maxconnections"] = "10"
default["jdbc"]["jdbc_minconnections"] = "1"
default["jdbc"]["jdbc_initsize"] = "1"
default["jdbc"]["jdbc_minidle"] = "1"
default["jdbc"]["jdbc_maxidle"] = "1"
default['jdbc']['jdbc_fcmaxidle'] = "5"
default['jdbc']['jdbc_fcminidle'] = "2"
default["jdbc"]["jdbc_maxactive"] = "100"
default["jdbc"]["jdbc_acquireincrement"] = "2"
# Java Log Levels
default["foundationlog"]["defaultloglevel"] = "INFO"
default["foundationlog"]["logger_foundationloglevel"] = [ ]
default["foundationlog"]["logger_maintloglevel"] = [ ]
default["foundationlog"]["logger_managementloglevel"] = [ ]
default["foundationlog"]["logger_reportloglevel"] = [ ]
default["foundationlog"]["logger_collabserverloglevel"] = [ ]
# Content Search
default["imagesearchEngine"] = "bingSearchEngine"
default["videosearchEngine"] = "youtubeSearchEngine"
default["websearchEngine"] = "bingSearchEngine"
# Email service default
default["emailservice"] = "testgmail"
# SMTP defaults
default['smtp']['apikey'] = "8b194147eae3f43ab6d2f241cc1670d0666"
default['smtp']['server'] = "10.0.1.224"
default['smtp']['port'] = "4569"
default['smtp']['smtp_from_address'] = "classflow@prometheanjira.com"
default['smtp']['validation_timeout'] = "10"
# Elasticsearch default
default["elasticsearch"]["cluster"]["name"] = "foundation"
default["elasticsearch"]["staffreindexthreads"] = "1"
default["elasticsearch"]["staffreindexbulk"] = "2000"
#Defaults for elasticsearch REST Service
default['elasticsearch']['rest_url'] = ""
default['elasticsearch']['rest_max_conn'] = "50"
default['elasticsearch']['rest_max_perhost'] = "50"
# Default SMTP
default["nfs_allow"] = "10.0.0.0/8"
default["smtp_from_address"] = "classflow@prometheanjira.com"
# Default Newrelic
default["newrelic"]["java-agent"]["jar_file"] = ""
default["newrelic"]["license"] = "de32ce382f0864624db5eaa83221b5350a619e25"
default['newrelic']["newrelic-plugin-install"] = "false"
# Default Environments to not create beaver agents for
default["nologging"] = ["local", "_default", "localdemo", "localpoc", "localappliance"]
# Default Environment for glusterfs servers
default["gluster_env"] = "tools"
# SIS/SFTP Server defaults
default["sftp"]["enable"] = "false"
default["sftp"]["sisremotedir"] = "/"
default["sftp"]["sislocaldir"] = "/opt/tomcat/sisimport/"
default["sftp"]["pollingservicecron"] = "0 0/5 * * * ?"
default["sftp"]["pollinggatewaytimeout"] = "30000"
default["localpollinginterval"] = "300000"
# AF A new job is created to deletes lessons of type TEMP
default["lessoncleancron"] = "0 0 0/2 * * ?"
default["lessoncleanup"] = "false"
default["lessconcleanint"] = "24"
# Tenant Config Attributes
default["fconfig"]["tenant_environment"] = "false"
default["fconfig"]["server_repo_url"] = "localhost"
default["fconfig"]["server_repo_user"] = "resourcepack@classflow.com"
default["fconfig"]["server_repo_pass"] = "Prom!R3sourcePk#"
default["fconfig"]["server_repo_name"] = "Resource Pack"
default["fconfig"]["server_repo_studentaccess"] = "1"
default["fconfig"]["founconfigdb"] = "fconfigdev"
default["fconfig"]["founconfiguser"] = "fconfigdevuser"
default["fconfig"]["founconfigpass"] = "fconfigdevpass"
# IN-508 - chef-client metrics
default["chef_client"]["handler"]["graphite"]["host"] = "10.0.1.209"
default["chef_client"]["handler"]["graphite"]["port"] = "2003"
default["chef_client"]["handler"]["status"] = "false"
# IN-1033 - chefgem-chef-api patch
default["chef_api"]["chef_api_patch"] = "false"
# Local server defaults
default['local']['localusername'] = "promethean"
default['local']['localuserpass'] = "Promethean1"
default['local']['localuserpasshash'] = "$1$3KXDj/NQ$dbhkX9bmE6ncUlkWxKygt0"
# BING API Key
default['bingapi.key'] = "+rNrJaXs9CdUGdpvMwRoyEr+WsAoMx3SMNIzZ2VecfQ"
# Defaults for elasticache
default['elasticache']['server'] = "localhost"
default['elasticache']['port'] = "6379"
# Defaults for postfix
default['smtp']['mailhost'] = "mail.prometheanjira.com"
default['smtp']['domain'] = "prometheanjira.com"
default['smtp']['networks'] = "127.0.0.0/8, 10.0.0.0/16, 172.31.0.0/16"
# Defaults for zookeeper - Keeping attributes in sync
default['zookeeper']['maxbuffer'] = "10485760"
