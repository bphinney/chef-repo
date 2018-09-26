# Chef attributes
default["chefclient_daemon"] =  "false"
default['chef_server']['environment'] = "USA - Dev/QA"
default['chef']['allow_insecure'] = "false"
default['chef']['release_list'] = "ram.venkataraman@prometheanworld.com ahmad.aslami@prometheanworld.com william.baleson@prometheanworld.com jennifer.jones@prometheanworld.com steven.gerald@prometheanworld.com andrew.burtnett@prometheanworld.com carlos.londono@prometheanworld.com devops@prometheanproduct.com"
default['chef']['datacenter'] = "QA/Dev Region"
# Defaults for glusterfs data bag creation
default['gluster']['noenvirons'] = [ "_default", "tools" ]
# Security Hardening Defaults
default["hardening"]["haproxyservice"] = "enable"
default["hardening"]["sftpaccess"] = "enable"
default["hardening"]["rsyncaccess"] = "enable"
default["hardening"]["tar"] = "enable"
default["hardening"]["zip"] = "enable"
default["hardening"]["scpaccess"] = "enable"
default["hardening"]["ftpaccess"] = "enable"
default["hardening"]["remoteroot"] = "enable"
default["hardening"]["emailreports"] = "disable"
default["hardening"]["localfirewall"] = "disable"
default["hardening"]["sshtunnels"] = "enable"
# Atlassian attributes
default['atlassian']['wiki_user'] = ''
default['atlassian']['wiki_pass'] = ''
# Vagrant whitelist defaults
default['vagrant']['whitelist'] = "false"
# Jumpbox defaults
default['jumpbox']['servername'] = "jd-jumpbox-1a"
default['jumpbox']['wikipage'] = "Self-Serve+javadevjumpbox.prometheanjira.com+Access"
