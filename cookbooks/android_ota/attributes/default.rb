# Default settings for android_ota cookbook

#### aws defaults ####
default['android_ota']['sftp_elbname'] = 'android-ota-update'

#### nginx defaults ####
default['android_ota']['host_url'] = 'placeholderota.prometheanworld.com' 
default['android_ota']['htpasswd_password'] = 'password'

#### mysql defaults ####
# PHP will sometimes default to a unix socket if 'localhost' is used
default['android_ota']['db_hostname'] = '127.0.0.1'
default['android_ota']['db_service']  = 'ota'

#### SFTP (Proftpd) defaults ####
# mysql
default['android_ota']['sftp_dbname'] = 'androidota'
default['android_ota']['sftp_dbuser'] = 'root'
default['android_ota']['sftp_dbpass'] = 'password'
# ftp
default['android_ota']['sftp_root'] = '/store' # TODO: Remove role redundancy
default['android_ota']['sftp_port'] = '2222' 

#### Zidoo ota4user application defaults ####
default['android_ota']['ota4user_dbname'] = 'ota4user' 
default['android_ota']['ota4user_dbuser'] = 'root' 
default['android_ota']['ota4user_dbpass'] = 'password' 
