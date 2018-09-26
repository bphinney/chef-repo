# Contains methods that associate with tenant provisioning and write operations

require_relative 'apiconnect'
require_relative 'sshconnect'

class TenantProvision
  include ApiConnect
  include SSHConnect

  # Method finds foundation-maint on remote node and initiates provided command
  def foundation_maint_run(node, command)
    # Looks up name of foundation-maint jar on node
    maint_jar = 'ls -1 /opt/tomcat/bin/maint | grep "jar$"'
    jar_file  = run_ssh_command(node, maint_jar)[0].chomp
    # Constructs full maint command with exit status
    # NOTE: Per Shameet, foundation-maint does not currently provide proper exit codes
    #       Returned exit code is not currently acted upon
    f_maint   = "cd /opt/tomcat/bin/maint; java -jar #{jar_file} -o #{command}; echo $PIPESTATUS"
    logger.debug "#{f_maint}"
    maint_ret = run_ssh_command(node, f_maint)
    return maint_ret[2] # exit code
  end

  # Method provisions and and loads the activfoundation schema for the tenant
  def remote_schema_create(dbcheck, tenant_config, tenant_status)
    chef_connect  = chef_api_connect
    tenant_name   = tenant_config['tenant_name']
    tenant_env    = tenant_config['env']
    tenant_schema = tenant_config['tenant_config.schema_name']
    db_username   = tenant_config['datasource.user_name']

    # Chooses random foundation-maint node from available
    fmaint_node   = dbcheck.lookup_backend_servers(tenant_env).sample(random: Random.new)
    mysql_connect = mysql_api_connect(tenant_env, rootuser=true)
    client        = mysql_connect[0] # mysql connection
    fconfigdb     = mysql_connect[1] # tenant config schema for env

    # Schema preparation commands
    # Required tenant name is passed directly to the command, here
    liquibase = "liquibaseUpdate -s activfoundation -c #{tenant_name}"
    bulkload  = "bulkLoad -c #{tenant_name}"
    reindex   = "reIndex -t all -c #{tenant_name}"

    logger.info "Creating database #{tenant_schema}"
    client.query("create database #{tenant_schema} character set utf8 collate utf8_general_ci")
    client.query("grant all privileges on #{tenant_schema}.* to #{db_username}@'%'")
    logger.info "Created database #{tenant_schema}"

    logger.info "Performing liquibase update for #{tenant_schema} on #{fmaint_node}."
    $time_start = Time.now
    foundation_maint_run(fmaint_node, liquibase)
    $time_liquibase = Time.now
    logger.info "Performing bulkloading for #{tenant_schema} on #{fmaint_node}."
    foundation_maint_run(fmaint_node, bulkload)
    $time_bulkload = Time.now
    logger.info "Performing reindex for #{tenant_schema} on #{fmaint_node}."
    foundation_maint_run(fmaint_node, reindex)
    $time_reindex = Time.now

    tenant_status['schema_complete'] = true
    return tenant_status
  end

  # Method inserts a default server repo for the tenant
  # Bypasses configuration for resource pack tenants,
  # automatically determined based on feature flag in tenant fconfig
  def add_server_repo(tenant_config, tenant_status)

    # If configuring a Resource Pack tenant, bypass default server repo
    if tenant_status['resource_pack'] == true
      logger.info "Resource Pack Tenant Feature is ACTIVE in tenant FCONFIG"
      logger.info "Bypassing Server Repo Configuration."
    else
      tenant_id     = tenant_config['tenant_config.id']
      tenant_name   = tenant_config['tenant_name']
      tenant_env    = tenant_config['env']
      chef_connect  = chef_api_connect
      mysql_connect = mysql_api_connect(tenant_env, rootuser=true)
      client        = mysql_connect[0] # mysql connection
      fconfigdb     = mysql_connect[1] # tenant config schema for env

      # Required values for server repo
      environ = chef_connect.search.query(:environment, "name:#{tenant_env}")
      environ.rows.each do |envitem|
        @server_repo_url    = envitem['default_attributes']['fconfig']['server_repo_url']
        @server_repo_user   = envitem['default_attributes']['fconfig']['server_repo_user']
        @server_repo_pass   = envitem['default_attributes']['fconfig']['server_repo_pass']
        @server_repo_name   = envitem['default_attributes']['fconfig']['server_repo_name']
        @server_repo_access = envitem['default_attributes']['fconfig']['server_repo_studentaccess']
      end

      server_repo_sql = "USE #{fconfigdb};
        INSERT INTO server_repo(
        id, name, description, tenant_config_id, server_url,
        username, password, last_updated_by, last_updated_on,
        created_by, created_on, has_student_access)
        VALUES(
        replace(uuid(),'-','') ,
        '#{@server_repo_name}',
        'ClassFlow Resource Pack',
        '#{tenant_id}',
        '#{@server_repo_url}',
        '#{@server_repo_user}',
        '#{@server_repo_pass}',
        'SYSTEM', NOW(), 'SYSTEM', NOW(),
        '#{@server_repo_access}');"

#=begin
      push_sql = client.query("#{server_repo_sql}")
#=end
      logger.info "Added default server repo for tenant #{tenant_name}"
      tenant_status['server_repo'] = true
    end
    return tenant_status
  end


  def provision_dns_route_53(dbcheck, tenant_config, tenant_status)
    tenant_name  = tenant_config['tenant_name']
    tenant_env   = tenant_config['env']
    subdomain    = tenant_status['subdomain']
    subcollab    = tenant_status['subcollab']
    zone_name    = tenant_status['zone_name']
    rt_connect   = dbcheck.determine_cname_api(zone_name)

    # tenant_status cname defaults
    tenant_status['sub_cname_provisioned']    = false
    tenant_status['collab_cname_provisioned'] = false

    # Aws hosted zone id for write operations
    record_id  = dbcheck.lookup_record_id_route53(zone_name)

    # Assign frontend and collab elbs
    balancers  = dbcheck.lookup_load_balancers(zone_name, tenant_env)
    frontend_elb, collab_elb = balancers[0], balancers[1]

    logger.info "Provisioning new entry for tenant #{tenant_name}"
    if tenant_status['sub_exists'] == false
      # Create primary tenant CNAME
      begin
#=begin
        rt_connect.change_resource_record_sets({
          hosted_zone_id: record_id,
          change_batch: {
            changes: [
              {
                action: "CREATE",      # accepts CREATE, DELETE, UPSERT
                resource_record_set: {
                  name: "#{subdomain}.#{zone_name}",
                  type: "CNAME",
                  ttl: 30,
                  resource_records: [
                    {
                      value: frontend_elb,
                    },
                  ],
                },
              },
            ],
          },
        })
#=end
        logger.info "Added new frontend CNAME records for tenant #{tenant_name}."

        tenant_status['sub_cname_provisioned'] = true
      rescue Aws::Route53::Errors::ServiceError => e
        logger.error "CNAME Provisioning failure: #{e.message} (#{tenant_name})"
      end
    else
      logger.warn "Bypassing CNAME entry for tenant #{tenant_name}."
    end

    if tenant_status['collab_exists'] == false
      # Create tenant-collab CNAME
      begin
#=begin
        rt_connect.change_resource_record_sets({
          hosted_zone_id: record_id,
          change_batch: {
          changes: [
              {
                action: "CREATE",      # accepts CREATE, DELETE, UPSERT
                resource_record_set: {
                  name: "#{subcollab}.#{zone_name}",
                  type: "CNAME",
                  ttl: 30,
                  resource_records: [
                    {
                      value: collab_elb,
                    },
                  ],
               },
              },
            ],
          },
        })
#=end
        logger.info "Added new collab CNAME records for tenant #{tenant_name}."
        tenant_status['collab_cname_provisioned'] = true
      rescue Aws::Route53::Errors::ServiceError => e
        logger.error "CNAME Provisioning failure: #{e.message} (#{tenant_name})"
      end
    else
      logger.warn "Bypassing CNAME entry for tenant #{tenant_name}."
    end
    return tenant_status
  end


  # Method connects to frontend boxes for environment and initiates a
  # vhost-specific chef-client run for the tenant
  def chef_vhost_update(dbcheck, tenant_config, tenant_status)
    tenant_status['vhost_updated'] = false
    tenant_env = tenant_config['env']
    front_end  = dbcheck.lookup_frontend_servers(tenant_env)
    command    = "chef-client -o prom-classfront::classflow-conf"
    front_end.each do |instance|
      logger.info "Updating vhost through chef-client run on #{instance}."
      begin
      run_ssh_command(instance, command)
      #response = run_ssh_command(instance, command)
      #chefresp = response[0]
      #exitcode = response[2]
      # Generates a runtime error if chef-client run fails
      #if exitcode = '1'
      #  raise RuntimeError.new(chefresp)
      #end
      # Provides error details on connection failure
      rescue SocketError => e
        logger.error "Unable to update vhost on instance #{instance}"
        logger.error "#{e}"
      # Returns chef-client output to log on failure
      #rescue RuntimeError => e
      #  logger.error "Chef runtime error on instance #{instance}"
      #  logger.error "######## CHEF-CLIENT RUN OUTPUT ###########"
      #  logger.error "#{e}"
      #  logger.error "####### END CHEF-CLIENT RUN OUTPUT ########"
      end
    end
    tenant_status['vhost_updated'] = true
  end

  # Method performs chef vhost updates on environments with new tenants
  def bulk_vhost_update(dbcheck, tenant_array)
    #tenant_status['vhost_updated'] = false
    command = "chef-client -o prom-classfront::classflow-conf"

    # list of environments that require vhost updates
    tenvs = [] 
    tenant_array.each do |tenant|
      tenant_config  = tenant[0]
      tenant_status  = tenant[1]
      tenvs << tenant_config['env']
    end
    tenant_envlist = tenvs.uniq
    tenant_envlist.each do |tenant_env|
      front_end  = dbcheck.lookup_frontend_servers(tenant_env)
      front_end.each do |instance|
        logger.info "Updating vhost through chef-client run on #{instance}."
        begin
        run_ssh_command(instance, command)
   
        # Provides error details on connection failure
        rescue SocketError => e
          logger.error "Unable to update vhost on instance #{instance}"
          logger.error "#{e}"
        end
      end
    end
    
    # Mark each tenant as updated
    tenant_array.each do |tenant|
      tenant_status  = tenant[1]
      tenant_status['vhost_updated'] = true
    end
  end

  # Method looks up tenant credentials on a provided sftp-server
  # Returns array with username:pass per proftpd convention
  def check_tenant_sftp_credentials(tenant, env, sftp_server)
    tenant_base      = tenant.split('.')[0]
    # lookup of sftp credentials as defined by proftpd and prom-sftp cookbook
    get_account      = "cat /etc/proftpd/foundation#{env}.current | grep #{tenant_base}"
    sftp_credentials = run_ssh_command(sftp_server, get_account)
    if sftp_credentials.nil?
      return nil
    else
      # Return only the creds portion of the ssh command response, and clear newline
      return sftp_credentials[0].chomp
    end
  rescue SocketError => e
    logger.warn "Unable to connect to #{sftp_server} for tenant sftp credentials"
    return nil
  end

  def check_tenant_sftp_port(env)
    sftp_port    = ''
    chef_connect = chef_api_connect
    chef_api_connect.search.query('sftp', "id:foundation#{env}", start: 0).rows.each do |item|
      sftp_port = item['raw_data']['foundationport']
    end
    return sftp_port
  rescue => e
    logger.warn "Unable to lookup sftp port for environment #{env}"
    return '####'
  end

  # Method connects to sftp-server and runs chef-client
  def chef_sftp_update(sftp_server)
    command = "chef-client -o prom-sftp::sftp-tenant"
    logger.info "Running sftp-tenant through chef-client run on #{sftp_server}."
    begin
    run_ssh_command(sftp_server, command)
    rescue SocketError => e
      logger.warn "Unable to run chef-client on #{sftp_server} for tenant-sftp"
      logger.error "#{e}"
    end
  end

  # Method connects to sftp server for valid tenants and produces/queries sftp credentials.
  # Returns sftp credentials if produced/found
  def produce_tenant_sftp_creds(dbcheck, tenant_config, tenant_status)
    tenant_name = tenant_config['tenant_name']
    tenant_env  = tenant_config['env']
    tenant_sis  = tenant_config['feature_set.entitlementlearningstandard'] # identifies sftp tenant
    tenant_lstd = tenant_config['feature_set.rostersis']                   # identifies sftp tenant
    # Should only be one sftp-server, typically in the 'tools' environment.
    sftp_server = dbcheck.lookup_servers_by_role('tools', 'sftp_server')[0]

    # SFTP requires rostersis or entitlementlearningstandard features to be turned on
    if tenant_sis.nil? && tenant_lstd.nil?
      logger.info "#{tenant_name} - Not configured for SFTP Access"
      return
    end

    begin
    # Get sftp account details, or run chef-client and run the check again.
    sftp_creds = check_tenant_sftp_credentials(tenant_name, tenant_env, sftp_server)
    if sftp_creds.empty? 
      chef_sftp_update(sftp_server)
      sftp_creds = check_tenant_sftp_credentials(tenant_name, tenant_env, sftp_server)
    end

    sftp_acct = sftp_creds.split(':')
    user_name = sftp_acct[0]
    user_pass = sftp_acct[1]
    user_port = check_tenant_sftp_port(tenant_env)
    logger.info "#{tenant_name} - Tenant is configured for SFTP Access"
    puts "#{tenant_name} - #### SFTP Credentials (NOT LOGGED) ####"
    puts "#{tenant_name} - SFTP User: #{user_name}"
    puts "#{tenant_name} - SFTP Pass: #{user_pass}"
    puts "#{tenant_name} - SFTP Port: #{user_port}"
    puts "#{tenant_name} - #### SFTP Credentials (NOT LOGGED) ####"
    rescue => e
      logger.error "There was a problem checking sftp credentials for tenant #{tenant_name}"
      logger.error "#{e}"
    end
  end

  # Method writes a quick provisioning status update to the tenant data bag
  def mark_tenant_provisioned(tenant_config, tenant_status)
    tenant_status['mark_provisioned'] = false
    tenant_name  = tenant_config['tenant_name']
    tenant_env   = tenant_config['env']
    chef_connect = chef_api_connect
    chef_connect.data_bags.fetch('foundation').items.each do |item|
      if item.id == tenant_name
        @prov_tenant = item
        @prov_tenant.data['is_provisioned'] = true
        @prov_tenant.save
        logger.info "Provisioning for #{tenant_name} is complete on #{tenant_env}."
      end
    end
    tenant_status['mark_provisioned'] = true
    return tenant_status
  end
end

