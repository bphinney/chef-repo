# Contains methods that associate with tenant validations and read-only operations
require_relative 'apiconnect'

class TenantCheck
  include ApiConnect

  # Method checks a string for uppercase characters
  # Returns true if at least one is found
  def has_uppers(t_string)
    str = t_string.match(/\p{Upper}/)
    !str.nil? ? true : false
  end

  # Method returns array of environments marked as hosting tenants
  def obtain_tenant_environments
    envs = []
    chef_api_connect.search.query(:environment, 'tenant_environment:*', start: 0).rows.each do |environ|
      if environ['default_attributes']['fconfig']['tenant_environment'] == "true"
        envs << environ['name']
      end
    end
    return envs
  end

  # Method returns array of all tenants currently in the data bag
  # Chef dependent
  def fetch_foundation_tenants
    db_tenants = []
    chef_api_connect.search.query(:foundation, '*:*', start: 0).rows.each do |tenant|
      db_tenants << tenant['raw_data']['id']
    end
    return db_tenants
  end

  # Method creates/updates foundation tenant data bag on a per-tenant basis
  def chef_refresh_tenant(tenant, auto=false)
    logger.info "#{tenant} - Refreshing DATA BAG..."

    foundation_bag  = chef_api_connect.data_bags.fetch('foundation')
    tenant_envs     = obtain_tenant_environments
    current_tenants = fetch_foundation_tenants
    update_flag     = false

    # Acqure .feature data bag values for tenant attribute comparison
    feature_bag = {}
    chef_api_connect.search.query('foundation', 'id:.features', start: 0).rows.each do |item|
      feature_bag = item['raw_data']
    end

    tenant_envs.each do |envname|
      mysql_connect = mysql_api_connect(envname)
      client        = mysql_connect[0] # mysql connection
      fconfigdb     = mysql_connect[1] # tenant config schema

      # Acquire contextmode value for tenant attribute
      chef_api_connect.search.query('environment', "name:#{envname}").rows.each do |envitem|
        @contextmode = envitem['default_attributes']['database']['contextmode']
      end

      begin
      results = client.query("select * from #{fconfigdb}.tenant_config")
      results.each do |row_schema|
        tenant_bag = {}
        # Set initial tenant attributes from corresponding .tenant_config
        row_schema.each do |col_name, col_val|
          case col_name
          when 'tenant_name'
            tenant_bag['id']             = col_val
            tenant_bag['url']            = col_val
            tenant_bag['url_alias']      = col_val
            tenant_bag['tenant_name']    = col_val
            tenant_bag['tenant_header']  = col_val
            tenant_bag['tenant_status']  = 'active'
            tenant_bag['is_provisioned'] = 'false'
          when 'datasource_id' then
            tenant_bag['datasource.id'] = col_val    # for queries
          when 'id' then
            tenant_bag['tenant_config.id'] = col_val # for queries
          end
        end

        # Bypass remaining configuration if not the working tenant
        tenant_bag['id'] != tenant ? next : update_flag = true

        # Fetch and set additional tenant attributes outside of .tenant_config
        tenant_bag['env']     = envname
        tenant_bag['context'] = @contextmode

        # Queries are combined into multi-statement to reduce sql query load
        @sql_tenant_config = client.query("
        select * from #{fconfigdb}.tenant_config where tenant_name='#{tenant_bag['id']}';
        select * from #{fconfigdb}.datasource where id='#{tenant_bag['datasource.id']}';
        select ref_feature_code_id from #{fconfigdb}.tenant_feature where tenant_config_id='#{tenant_bag['tenant_config.id']}'
        ")
        while client.next_result
          @sql_tenant_datasource = client.store_result
          while client.next_result
            @sql_tenant_features = client.store_result
          end
        end

        # Construct .tenant_config attributes
        @sql_tenant_config.each do |tenant_config_row|
          tenant_config_row.each do |tenant_key, tenant_val|
            tenantconfigkey = "tenant_config.#{tenant_key}"
            tenant_bag[tenantconfigkey] = tenant_val
          end
        end

        # Fetch and construct .datasource attributes
        @sql_tenant_datasource.each do |ds_row|
          ds_row.each do |ds_key, ds_val|
            datasourcekey = "datasource.#{ds_key}"
            tenant_bag[datasourcekey] = ds_val
          end
        end

        # Fetch and construct .feature attributes
        @sql_tenant_features.each do |feature_row|
          feature_row.each do|_feature_key, feature_val|
            # Compare against useful features listed in .features data bag.
            feature_bag.each do |key,value|
              case feature_val
              when value
                tenant_bag[key] = value
              end
            end
          end
        end

        if current_tenants.include?(tenant)
          logger.info "#{tenant} - Updating DATA BAG.."

          chef_api_connect.search.query('foundation', "id:#{tenant_bag['id']}", start: 0).rows.each do |item|
            # Values to retain from existing tenant before updating
            tenant_bag['is_provisioned'] = item['raw_data']['is_provisioned']
            tenant_bag['url_alias']      = item['raw_data']['url_alias']
            tenant_bag['tenant_status']  = item['raw_data']['tenant_status']
            # Extra value extraced for tenant name lower-case checking
            @schema_case                 = item['raw_data']['tenant_config.schema_name']
          end

          # Uppercase letter check against tenant_config values 
          char_checks = [ tenant_bag['tenant_name'] , @schema_case ]
          char_checks.each do |item|
            if has_uppers(item)
              logger.error "Uppercase characters detected for #{item}, not updating DATA BAG..."
              abort "#{logger.error 'Aborting...' }" if !auto
            end
          end

          update_bag = foundation_bag.items.update(tenant)
          update_bag.data = tenant_bag
        else
          logger.info "#{tenant} - Creating new DATA BAG..."
          update_bag = foundation_bag.items.create(tenant_bag)
        end
        update_bag.save!
        logger.info "#{tenant} - DATA BAG saved."
        return tenant_bag
      end
      rescue Mysql2::Error => e
        logger.warn("Unable to connect to environment for #{envname}\n#{e}")
      end
    end
    if update_flag == false
      logger.error "#{tenant} - NO fconfig information was found, please review the tenant details."
      abort "#{logger.error 'Aborting...' }" if !auto
    end
  end

  # Method returns arrays of tenants and and schema names from fconfig
  def fetch_fconfig_tenants
    tenant_fconfig  = []
    tenant_envs     = obtain_tenant_environments
    tenant_envs.each do |envname|
      mysql_connect = mysql_api_connect(envname)
      client        = mysql_connect[0] # mysql connection
      fconfigdb     = mysql_connect[1] # tenant config schema
      results       = client.query("select * from #{fconfigdb}.tenant_config")
      results.each do |row_schema|
        row_schema.each do |col_name, col_val|
          @t_name   = row_schema['tenant_name']
          @t_schema = row_schema['schema_name']
        end
        tenant_fconfig << [@t_name, @t_schema]
      end
    end
    return tenant_fconfig
  end

  # Method returns current environment of single tenant based on fconfig
  def find_tenant_environment(tenant)
    tenant_envs     = obtain_tenant_environments
    tenant_envs.each do |envname|
      mysql_connect = mysql_api_connect(envname)
      client        = mysql_connect[0] # mysql connection
      fconfigdb     = mysql_connect[1] # tenant config schema
      results       = client.query("select * from #{fconfigdb}.tenant_config")
      results.each do |row_schema|
        row_schema.each do |col_name, _col_val|
          if col_name == "tenant_name"
            @tenant_env = envname
            return @tenant_env
          end
        end
      end
    end
    logger.error "Something is wrong, there HAS to be an env." if @tenant_env.nil?
    abort
  end

  # Method returns current environment of single tenant based on fconfig
  def find_tenant_schema(tenant)
    env           = find_tenant_environment(tenant)
    mysql_connect = mysql_api_connect(env)
    client        = mysql_connect[0] # mysql connection
    fconfigdb     = mysql_connect[1] # tenant config schema
    results = client.query("select * from #{fconfigdb}.tenant_config where tenant_name='#{tenant}'")
    results.each do |row_schema|
      row_schema.each do |col_name, col_val|
        if col_name == "schema_name"
          @tenant_schema = col_val
          return @tenant_schema
        end
      end
    end
    logger.error "Something is wrong, there should be a schema in fconfig" if @tenant_schema.nil?
    abort
  end

  # Method returns array of all urls associated with a tenant
  # For post validation
  def fetch_tenant_urls(tenant)
    tenant_urls     = {}
    tenant_envs     = obtain_tenant_environments
    tenant_envs.each do |envname|
      mysql_connect = mysql_api_connect(envname)
      client        = mysql_connect[0] # mysql connection
      fconfigdb     = mysql_connect[1] # tenant config schema
      begin
      results       = client.query("select * from #{fconfigdb}.tenant_config")
      results.each do |row_schema|
        row_schema.each do |col_name, col_val|
          case col_name
          when "tenant_name"
            if col_val == tenant
              tenant_urls['host_url']         = row_schema['host_url']
              tenant_urls['workspace_url']    = row_schema['teacher_workspace_url']
              tenant_urls['collabserver_url'] = row_schema['collabserver_url']         
              return tenant_urls
            end
          end
        end
      end
      rescue Mysql2::Error => e
        logger.warn("Unable to connect to environment for #{envname}\n#{e}")
      end
    end
  end

  # Method returns array of all url aliases currently in the data bag
  # Chef dependent
  def fetch_tenant_url_aliases
    db_aliases = []
    chef_api_connect.search.query(:foundation, '*:*', start: 0).rows.each do |tenant|
      # filters out nil values and tenants listed as part of aliases
      if !tenant['raw_data']['url_alias'].nil?
        db_aliases << tenant['raw_data']['url_alias'].split(' ')
                      .reject{|k| k == tenant['raw_data']['id']}
      end
    end
    return db_aliases.flatten!
  end

  # Method returns an array of afschemas for all environments
  def fetch_foundation_schemas
    tenant_schemas = []
    client         = mysql_api_connect('root')
    # schemas only start with af* by convention, so check all of them
    results        = client.query('show databases')
    results.each do |row|
      row.each do |_col_name, col_val|
        tenant_schemas << col_val
      end
    end
    return tenant_schemas
  end

  # Method returns array of instances selected by role and environment
  def lookup_servers_by_role(environment, role)
    cluster = []
    servers = chef_api_connect.search.query(:node, "role:*#{role}", start: 0)
    servers.rows.each do |item|
      item.each do |k, v|
        case k
        when 'name'
          @node_name = v
        when 'chef_environment'
          cluster << @node_name if v == environment
        end
      end
    end
    return cluster
  end

  # Method returns array of backend foundation instances for environment
  def lookup_backend_servers(environment)
    cluster = []
    servers = chef_api_connect.search.query(:node, 'role:*foundationmaint', start: 0)
    servers.rows.each do |item|
      item.each do |k, v|
        case k
        when 'name'
          @node_name = v
        when 'chef_environment'
          cluster << @node_name if v == environment
        end
      end
    end
    return cluster
  end

  # Method returns array of backend foundation instances for environment
  def lookup_frontend_servers(environment)
    cluster = []
    servers = chef_api_connect.search.query(:node, 'role:*frontend', start: 0)
    servers.rows.each do |item|
      item.each do |k, v|
        case k
        when 'name'
          @node_name = v
        when 'chef_environment'
          cluster << @node_name if v == environment
        end
      end
    end
    return cluster
  end

  # Method determines if cname is in alternate datacenter
  # And returns appropriate IAM authenticated client
  def determine_cname_api(zone)
    aws_ec2_az  = `curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`.strip
    node_region = aws_ec2_az[0..-2] # local node region
    zone_region = ''
    iam_arn     = ''
    iam_session = ''

    chef_api_connect.search.query(:zones, 'id:*', start: 0).rows.each do |db_item|
      if zone == db_item['raw_data']['record_name'] && db_item['raw_data']['active']
        # Only require region if local
        if node_region == db_item['raw_data']['iam_region']
          zone_region = db_item['raw_data']['iam_region']
        # Acqure iam components if not local region
        else
          zone_region = db_item['raw_data']['iam_region']
          iam_arn     = db_item['raw_data']['iam_arn']
          iam_session = db_item['raw_data']['iam_session']
        end
      end
    end

    if !iam_arn.nil?
      # Use cross-account sts authentication
      connect = aws_sts_connect('Route53_Client', iam_arn, iam_session, zone_region)
    else
      # Use current account authentication
      connect = aws_api_connect('Route53_Client')
    end
    return connect   
  end

  # Method looks up zone reference id for a provided zone on Route 53
  # Route 53 record ID is required for some Route 53 API operations
  def lookup_record_id_route53(zone)
    @tries ||= 0
    rt_connect = determine_cname_api(zone)
    page_rate  = 100 # Route 53 api can return max 100 records at at time
    record_list = rt_connect.list_hosted_zones_by_name({
                  max_items: page_rate,
                  })
    loop do
      record_list.hosted_zones.each do |record|
        @hosted_zone = record.name.chomp('.') # removes trailing period
        if @hosted_zone == zone
          return record.id
        end
      end
      # Iterate any subsequent sets of dns names
      if record_list.is_truncated
        record_list.next_dns_name
      else
        return nil
      end
    end
  rescue Aws::Route53::Errors::Http500Error => e
    api_wait = (@tries += 1)**2
    logger.warn "Error connecting to Route 53, retrying in #{api_wait} seconds"
    logger.warn "#{e}"
    sleep(api_wait)
    retry unless @tries >= 4
  end

  # Method returns array of data for a specified DNS zone in Route 53
  # Returns false if record is not found
  def lookup_records_route53(tenant_sub, zone)
    # Bypass for the special little snowflake that is Beijing
    if zone = 'classflow.cn'
      logger.info "Zone detected as China, bypassing cname lookup for #{tenant_sub}"
      return false
    end
    rt_connect  = determine_cname_api(zone)
    record_id   = lookup_record_id_route53(zone)
    page_rate   = 100 # Route 53 api returns 100 records at at time
    hold_record = nil # Starts at nil so it is initially ignored by aws api

    unless record_id.nil? or record_id.empty?
      loop do
        record_count = 0
        record_list = rt_connect.list_resource_record_sets({
                  start_record_name: hold_record,
                  hosted_zone_id: record_id,
                  max_items: page_rate,
                  })
        record_list.resource_record_sets.each do |record|
          # splits subdomain from zone, removes trailing '.'
          record_content = record.name.rpartition(zone)[0].chomp('.')
          record_count += 1
          if record_content == tenant_sub
            return record_id, record_content
          end

          # Holds last record to use as start point for the next set
          hold_record = record.name
        end
        # Checks every 100 record set for a match
        # If the set is less than 100, it is the last set
        if record_count < 100
          return false
        end
      end
    end
  end

  # Method parses and validates tenant domains against data bag
  # Returns cname hash of parsed cname data
  def parse_tenant_cnames(tenant)
    zones = []
    cname = {}
    chef_api_connect.search.query(:zones, 'id:*', start: 0).rows.each do |db_item|
      if !db_item['raw_data']['record_name'].nil? && db_item['raw_data']['active']
        zones << db_item['raw_data']['record_name']
      end
    end
    # Removes nil results from domain list
    zones = zones.reject { |item| item.nil? || item == '' }
    zones.each do |zone|
      # The "." is a syntax check - filters typos like fooclassflow.com or fo.oclassflow.com
      if tenant.include?('.' + zone)
        # Partitions on valid zone, allowing for extended subdomains
        @subdomain  = tenant.rpartition(zone)[0].chomp('.')
        @zone_name  = tenant.rpartition(zone)[1]
        @subcollab  = @subdomain + '-collab'
      end
    end

    # Exits on domain typos or incorrect zones for the environment
    if @zone_name.nil? || @zone_name == '' || @subdomain.nil? || @subdomain == '' || tenant.include?('..')
      logger.error 'Tenant name rejected! - it could be misspelled, invalid, or not yet configured.'
      logger.info 'Valid domains for this environment are:'
      zones[0].split(',').each { |zone| logger.info "#{zone}" }
      exit
    end

    cname['subdomain'] = @subdomain
    cname['subcollab'] = @subcollab
    cname['zone_name'] = @zone_name
    return cname
  end

  # Method returns hash of cname existence against indicated dns service
  def lookup_cname_status(cnames)
    cnames['collab_exists'] = false
    cnames['sub_exists']    = false
    subdomain_info = lookup_records_route53(cnames['subdomain'], cnames['zone_name'])
    subcollab_info = lookup_records_route53(cnames['subcollab'], cnames['zone_name'])
    cnames['sub_exists']    = true unless subdomain_info == false
    cnames['collab_exists'] = true unless subcollab_info == false
    return cnames
  end

  # Method returns AWS frontend/collab load balancers by tenant env and/or zone
  def lookup_load_balancers(tenant_zone, environment)
    begin
      chef_api_connect.search.query('zones', 'id:*', start: 0).rows.each do |db_item|
        if db_item['raw_data']['record_name'] == tenant_zone
          @frontend_elb = db_item['raw_data']["#{environment}"]['frontend_elb']
        end
      end
    rescue => e
      logger.error "Frontend elb not identified in data bag for tenant."
      logger.error "#{e}"
      abort
    end
    begin
      chef_api_connect.search.query('zones', 'id:*', start: 0).rows.each do |db_item|
        if db_item['raw_data']['record_name'] == tenant_zone
          @collab_elb = db_item['raw_data']["#{environment}"]['collab_elb']
        end
      end
    rescue => e
      logger.error "Collab elb not identified in data bag for tenant."
      logger.error "#{e}"
      abort
    end
    return @frontend_elb, @collab_elb
  end

  # Method checks the data bag and provisioning status of a single tenant
  # Returns hash of provisioning information related to tenant
  def check_tenant_status(tenant, auto=false)
    logger.info "#####################################"
    logger.info "#{tenant} - Checking tenant status..."
    tenant_config   = chef_refresh_tenant(tenant, auto) # Initial fconfig data
    tenant_status   = {} # Tenant provisioning state

    # Attributes acquired from tenant fconfig
    @tenant_id      = tenant_config['id']
    @tenant_name    = tenant_config['tenant_config.tenant_name']
    @schema_name    = tenant_config['tenant_config.schema_name']
    @tenant_active  = tenant_config['tenant_config.active']
    @default_status = tenant_config['tenant_config.is_default_tenant']
    @collab_url     = tenant_config['tenant_config.collabserver_url']
    @tenant_secret  = tenant_config['tenant_config.secret']
    @resource_pack  = tenant_config['feature_set.configclassflowresourcepacktenant']
    # Chef data bag attributes NOT in tenant fconfig
    @tenant_context = tenant_config['context']
    @tenant_aliases = tenant_config['url_alias']
    @prov_status    = tenant_config['is_provisioned']

    # keep the tenant name with the tenant_status hash for quick access
    tenant_status['tenant_name'] = @tenant_name

    # Uppercase letter check against tenant_config values 
    # Characers cause problems with elasticsearch
    char_checks = [ @tenant_name, @schema_name ]
    char_checks.each do |item|
      if has_uppers(item)
        logger.error "Uppercase characters detected for #{item}"
        abort "#{logger.error 'Aborting...' }" if !auto
      end
    end

    # Validate collabserver url
    # url must include -collab due to string checking mechanism in foundation
    # collab url with /activfoundation is invalid as of 4.0 and must be removed
    if !@collab_url.include?('-collab') || @collab_url.include?('activfoundation')
      logger.error "The Collab url for #{@tenant_name} appears to be misconfigured in fconfig"
      abort "#{logger.error 'Aborting...' }" if !auto
    end
    # Trailing slashes break collab
    if @collab_url[-1] == '/'
      logger.error "The Collab url for #{@tenant_name} has a trailing slash in it, Richard."
      abort "#{logger.error 'Aborting...' }" if !auto
    end

    # Tenant should include the default SAML password
    # to avoid restarts when configuring SAML
    if @tenant_secret.nil?
      logger.warn "Tenant Secret value is not set for this tenant!"
    end

    # Check to see if marked as a default tenant
    if @default_status == "\u0001"
      logger.warn "#{tenant} - MARKED AS DEFAULT TENANT in DATA BAG"
      tenant_status['marked_default_tenant'] = true
    end

    # Check to see if schema has already been provisioned
    schemas = fetch_foundation_schemas
    if schemas.include?(@schema_name)
      logger.warn "#{tenant} - SCHEMA #{@schema_name} currently exists"
      tenant_status['schema_exists'] = true
    else
      logger.info "#{tenant} - SCHEMA #{@schema_name} does not yet exist"
      tenant_status['schema_exists'] = false
    end

    # Indicates tenant active status. No actions performed on this yet
    if @tenant_active == "\u0001"
      logger.info "#{tenant} - Marked as ACTIVE"
      tenant_status['marked_active'] = true
    else
      logger.info "#{tenant} - Marked as NOT ACTIVE"
      tenant_status['marked_active'] = false
    end

    # Determines whether tenant is a resource pack tenant by feature
    if !@resource_pack.nil?
      logger.info "#{tenant} - Marked as a RESOURCE PACK TENANT"
      tenant_status['resource_pack'] = true
    else
      tenant_status['resource_pack'] = false
    end

    # Check to see if souschef/script has marked the tenant as provisioned already
    if @prov_status == 'true'
      logger.warn "#{tenant} - Marked as PROVISIONED in DATA BAG"
      tenant_status['is_provisioned'] = true
    else
      logger.info "#{tenant} - Marked as NOT provisioned in DATA BAG"
      tenant_status['is_provisioned'] = false
    end

    # Check fconfig tenants against all existing url aliases for duplicates
    d_aliases = fetch_tenant_url_aliases
    if d_aliases.include?(tenant)
      logger.warn "#{tenant} - URL ALIAS exists for another tenant"
      tenant_status['aliases_exist'] = true
    else
      logger.info "#{tenant} - URL ALIASES are clear"
      tenant_status['aliases_exist'] = false
    end

    # Check tenant cnames to see if they are already provisioned
    cnames       = parse_tenant_cnames(tenant)
    cname_status = lookup_cname_status(cnames)
    logger.warn "#{tenant} - CNAME \"#{cnames['subdomain']}\" exists for #{cnames['zone_name']}." if cname_status['sub_exists'] == true
    logger.warn "#{tenant} - CNAME \"#{cnames['subcollab']}\" exists for #{cnames['zone_name']}." if cname_status['collab_exists'] == true
    tenant_status.merge! cname_status  # keep cname data with tenant_status

    return tenant_config, tenant_status
  end

  # Method returns array of unprovisioned tenants based on afschema existence
  def find_unprovisioned_tenants
    logger.info '#### FCONFIG - Searching for unprovisioned tenants ####'
    candidates = []
    f_tenants  = fetch_fconfig_tenants
    d_tenants  = fetch_foundation_tenants
    db_schemas = fetch_foundation_schemas

    # Check for duplicate fconfig tenants or schemas
    # TODO: Separate and configure to work with single tenant provisionings
    dupe_tenants = f_tenants.transpose
    dupe_fconfig = dupe_tenants[0].group_by { |e| e }.select { |_k, v| v.size > 1 }.map(&:first)
    dupe_schemas = db_schemas.group_by { |e| e }.select { |_k, v| v.size > 1 }.map(&:first)
    if dupe_fconfig.empty? == false
      logger.error "Duplicate tenant identified, #{dupe_fconfig[0]}, exiting"
      exit
    end
    if dupe_schemas.empty? == false
      logger.error "Duplicate schema identified, #{dupe_schemas}, exiting"
      exit
    end

    f_tenants.each do |tenant|
      provisionable = false
      f_tenant_name, f_tenant_schema = tenant[0], tenant[1]
      # Check fconfig tenants against data bag
      if d_tenants.include?(f_tenant_name) == false
        logger.info "#{f_tenant_name}"
        logger.info "#{f_tenant_schema} - Tenant found in FCONFIG, not yet in DATA BAG"
        provisionable = true
      end
      # Check fconfig schemas against data bag
      if db_schemas.include?(f_tenant_schema) == false
        logger.info "## #{f_tenant_name} ##"
        logger.info "#{f_tenant_schema} - Schema is not provisioned"
        provisionable = true
      end
      # If either one is true, then provision the tenant
      if provisionable == true
        candidates << f_tenant_name
      end
    end
    logger.info '#### FCONFIG - Search complete ####'
    return candidates
  end

  # Method performs a url check against a tenant's collabserver endpoint
  # Reports a timeout if no http response is heard in x seconds
  def validate_tenant_urls(tenant)
    logger.info "#{tenant} - Validating collab url..."

    tenant_urls = fetch_tenant_urls(tenant)
    collab_url  = tenant_urls['collabserver_url'] + "/eventbus.html"
    uri         = URI(collab_url)
    time_out    = 30
    exceptions  = [SocketError, Net::HTTPFatalError]

    # pause for just a moment before validating
    sleep 10

    Timeout::timeout(time_out){
      begin
        response = Net::HTTP.get_response(uri)
        case response
        when Net::HTTPOK then
          logger.info "SUCCESS: 200 response from Collabserver for #{tenant}"
        else
          logger.error "Collabserver reports non-200 response: #{response.value}"
        end
      rescue *exceptions => e
        logger.error "Unable to connect to collabserver!"
        logger.error "Fconfig Collab endpoint: #{collab_url}"
        logger.error "#{e}"
      end
    }
    rescue Timeout::Error => e
    logger.error "Connection timeout to Collabserver after #{time_out} seconds"
    rescue TypeError => e
    logger.error "The provided tenant does not appear to be valid, please check"
  end
end
