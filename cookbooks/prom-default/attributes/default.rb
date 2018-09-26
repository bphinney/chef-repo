default["chefclient_daemon"] =  "false"
default['chef']['allow_insecure'] = "false"
default['chef_client']['disable_ohai_plugins'] = "false"
# Machine data
default["provider"] = "local"
default['cluster']['hosts_update'] = nil
# Yum repository Defaults
default["yum"]["yumserver"] = "yumrepo.prometheanjira.com"
default["yum"]["test_repo"] = "1"
default["yum"]["rel_repo"] = "0"
default["yum"]["promethean"]["metadata_expire"] = "15"
default["yum"]["yumrepo_server"] = "yumrepo"
default["yum"]["yumrepo_domain"] = "prometheanjira.com"
default["yum"]["yumrepo_allowip"] = [ "172.31.0.0/16", "10.0.0.0/8" ]
default["yum"]["yumrepo_reposync"] = [ "prometheanrelease", "prometheancommon", "prometheanspecial" ]
default["yum"]["yumrepo_data"] = "/data"
default["yum"]["yumrepo_dirlink"] = [ "common", "release", "special" ]
default["yum"]["cache_clean"] = "false"
default["yum"]["method"] = "http"
default["yum"]["datacenter_repo"] = "false"
# CentOS 7 EPEL Repository
default['epel']['epelserver'] = 'mirrors.fedoraproject.org'
default['epel']['path'] = '/pub/epel/7/'
default['epel']['repo_enable'] = '1'
default['epel']['gpg_file'] = '/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7'
# IN-1537 - gpg signing for rpm packages
default["yum"]["gpgcheck"] = "1"
default["yum"]["gpg_user"] = "ops.classflow@prometheanworld.com"
default["yum"]["gpg_pubkey_id"] = "407DAC0E"
default["yum"]["gpg_passphrase"] = "oFC2twQn0Ug0O*LiFENWdlNt"

# Adding excludes for yum
default['yum']['main']['exclude'] = "kernel*-2.6.32-642*"
