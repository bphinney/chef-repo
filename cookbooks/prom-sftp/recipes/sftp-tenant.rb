#
# Cookbook Name:: prom-sftp
# Recipe:: sftp-tenant
#
# Copyright 2014, Promethean
#
# All rights reserved - Do Not Redistribute
#


# Attributes in the data_bag sftp
begin
  foundationdbags = search(:sftp, "foundationroot:*")
  rescue Net::HTTPServerException
  Chef::Log.info("No foundationroot configuration attribues found in the sftp data bag.")
end

# Xfer User Details
standard_xfer_uid = "2002"
standard_xfer_gid = "2001"
standard_password = "01x3rn0w"

foundationdbags.each do |foundbag|
  track_passwd       = foundbag['foundationcurrent']
  foundationauthfile = foundbag['foundationauthfile']
  foundationroot     = foundbag['foundationroot']
  foundationenv      = foundbag['foundationenv']

  tenantenv_with_rostersis = search(:foundation, "feature_set.rostersis:* AND env:#{foundationenv}")
  tenantenv_with_learningstd = search(:foundation, "feature_set.entitlementlearningstandard:* AND env:#{foundationenv}")

  tenantenv_with_rostersis.each do |tenant|
     tenant_id      = tenant["tenant_config.id"]
     tenant_name    = tenant["tenant_config.tenant_name"]
     tenant_short   = tenant_name.split('.').first(1).join('.')
     tenant_parse   = tenant_short + ":"

     directory "#{foundationroot}/#{tenant_id}" do
       owner "root"
       group "root"
       mode  "0777"
       action :create
     end

       # Here we create a foundation-xfer user if one does not aleady exist, we 
       # actually look in the authfile to see if the user exist.   
     execute "foundation-xfer-usermgmt_#{tenant_parse}" do
       command "echo changeme|/usr/bin/ftpasswd --passwd --file=#{foundationauthfile} --name=#{tenant_short} --uid=#{standard_xfer_uid} --gid=#{standard_xfer_gid} --home=#{foundationroot}/#{tenant_id} --shell=/bin/false --stdin; echo -n #{tenant_parse} >> #{track_passwd}; openssl rand -base64 8|tee -a #{track_passwd}| ftpasswd --passwd --file=#{foundationauthfile} --change-password --name=#{tenant_short} --stdin"
       sensitive true
       action :run
       #not_if { IO.read("#{foundationauthfile}").include?("#{tenant_parse}") }
       only_if "[[ -z $(grep ^#{tenant_parse} #{foundationauthfile}) ]]"       
     end
  end

  tenantenv_with_learningstd.each do |tenant|
     tenant_id      = tenant["tenant_config.id"]
     tenant_name    = tenant["tenant_config.tenant_name"]
     tenant_short   = tenant_name.split('.').first(1).join('.')
     tenant_parse   = tenant_short + ":"

     directory "#{foundationroot}/#{tenant_id}" do
       owner "root"
       group "root"
       mode  "0777"
       action :create
     end

       # Here we create a foundation-xfer user if one does not aleady exist, we 
       # actually look in the authfile to see if the user exist.
     execute "foundation-xfer-usermgmt_#{tenant_parse}" do
       command "echo changeme|/usr/bin/ftpasswd --passwd --file=#{foundationauthfile} --name=#{tenant_short} --uid=#{standard_xfer_uid} --gid=#{standard_xfer_gid} --home=#{foundationroot}/#{tenant_id} --shell=/bin/false --stdin; echo -n #{tenant_parse} >> #{track_passwd}; openssl rand -base64 8|tee -a #{track_passwd}| ftpasswd --passwd --file=#{foundationauthfile} --change-password --name=#{tenant_short} --stdin"
       sensitive true
       action :run
       #not_if { IO.read("#{foundationauthfile}").include?("#{tenant_parse}") }
       only_if "[[ -z $(grep ^#{tenant_parse} #{foundationauthfile}) ]]"
     end
  end
end
