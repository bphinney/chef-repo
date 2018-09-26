#
# Cookbook Name:: atlassian-yumrepo
# Recipe:: yumrepo-gpg
#
# Copyright 2016, Promethean 
# All rights reserved - Do Not Redistribute
#
# Configures pgp private-key signing for promethean applications
# Supports single active key at this time
#

include_recipe 'prom-default'

ops_email      = node['yum']['gpg_user']
# Secure private Key Passphrase
gpg_passphrase = node['yum']['gpg_passphrase']
# Short public key identifier for key comparison
gpg_pubkey_id  = node['yum']['gpg_pubkey_id']
# Extracts short public key id from keyring for identification
keyring_short_key_id = `gpg --list-keys | grep -o -P '(?<=R/)[[:xdigit:]]{8}'`.chomp

# GnuPG default directory
directory '/root/.gnupg' do
  owner 'root'
  group 'root'
  mode  '0700'
end

# Macros file to setup required variables for application signing
template '/etc/rpm/macros.promethean' do
  source 'macros.promethean.erb'
  owner  'root'
  group  'root'
  mode   '0755'
  variables(
    ops_email: ops_email
  )
end

# Temporary GPG Batch File
template '/tmp/gpg-genkey.conf' do
  source 'gpg-genkey.conf.erb'
  owner  'root'
  group  'root'
  mode   '0755' 
  action 'create'
  only_if { keyring_short_key_id.empty? }
  variables(
    ops_email:      ops_email,
    gpg_passphrase: gpg_passphrase
  )
end

# PGP key generation requires entropy to be manufactured during key creation,
# even when running with the --batch flag. The following initiates a file-write 
# process to boost entropy and allow the gpg process to complete. Until Aws releases 
# a quantum entropy service api, this seems to provide consistent results.
bash 'generate-gpg-key' do
  code <<-EOH
# Begin a process to initiate disk writes and generate required entropy
# for pgp key verification
(dd bs=1M count=2048 if=/dev/zero of=/tmp/emptyfile conv=fdatasync) &

# Generate gpg keys using batch operation and temporary configfile
gpg2 --batch --gen-key /tmp/gpg-genkey.conf

# Remove produced emptyfile
rm -f /tmp/emptyfile
  EOH
  only_if { keyring_short_key_id.empty? }
  # gpg returns a socket connection failure to STDERR by design
  ignore_failure true
end

# Remove temporary GPG Batch File
template '/tmp/gpg-genkey.conf' do
  source 'reindex_stable.sh.erb'
  owner  'root'
  group  'root'
  mode   '0755' 
  action 'delete'
  only_if { `test -f /tmp/gpg-genkey.conf` }
end

# Backup keychain in case values change
execute 'backup_gnupg' do
  command "tar cf /opt/gpg_backup/gpgbackup_#{keyring_short_key_id}.tar.gz /root/.gnupg"
  action :nothing
end

directory '/opt/gpg_backup' do
  owner  'root'
  group  'root'
  mode   '0755'
  # backup keychain at point the id can be read
  only_if { !keyring_short_key_id.empty? }
  # backup on unexpected keychain change
  only_if { gpg_pubkey_id != keyring_short_key_id }
  # don't clobber existing keychain
  not_if  { File.exists?("/opt/gpg_backup/gpgbackup_#{keyring_short_key_id}.tar.gz") }
  notifies :run, "execute[backup_gnupg]"
end

include_recipe 'atlassian-yumrepo::yumrepo-sign'
