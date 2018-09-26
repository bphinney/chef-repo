#!/opt/chef/embedded/bin/ruby -W0
#
# Cookbook Name:: promethean
# Recipe:: chef_tenant_update
#
# Copyright 2016, Promethean
#
# All rights reserved - Do Not Redistribute
#

require 'mysql2'
#%x(chef-client -o prom-chef::chef-api-gem)
require 'chef-api'
ChefAPI.log_level = :fatal

# Method acquires chef credentials from user environment knife.rb
def chef_credentials
  creds = Hash.new
  File.open(ENV['HOME'] + '/.chef/knife.rb').each do |line|
    creds['c_uri']  = line.scan(/'([^']*)'/).join(' ') if line.match('chef_server_url')
    creds['c_key']  = line.scan(/'([^']*)'/).join(' ') if line.match('client_key')
    creds['c_node'] = line.scan(/'([^']*)'/).join(' ') if line.match('node_name')
  end
  return creds
rescue => e
  puts '(chef=>tenant_prov): Unable to access Chef credentials. Check the knife.rb file for the user environment.'
  puts "(chef=>tenant_prov): Error: #{e}"
  exit
end

# Method connects using chef-api gem and provided credentials
def chef_api_connect
  # Configured with retries as chef-api occasionally fails on connection
  tries ||= 60
  chefcreds = chef_credentials
  connection = ChefAPI::Connection.new(
    client:     chefcreds['c_node'],
    key:        chefcreds['c_key'],
    ssl_verify: false,
    endpoint:   chefcreds['c_uri']
  )
  return connection
rescue  => e
  puts "Chef API Timeout, retrying..."
  retry unless (tries -= 1).zero?
end

# Method acquires mysql credentials from either environment or data bag
# Returns connection/schema for environment, or root bypass connection
def mysql_api_connect(environment, rootuser=false)
  db_creds = Hash.new
  # Returns a root only connection if "root" string is defined in lieu of environment
  if environment == "root"
    chef_api_connect.search.query(:mysql, 'id:mysqlserver').rows.each do |db_item|
      db_creds[:user] = db_item['raw_data']['mysqladminuser']
      db_creds[:pass] = db_item['raw_data']['mysqladminpass']
      # NOTE: Workaround to remove host port concatenation in mysql data bag
      db_creds[:host] = "#{db_item['raw_data']['mysqlwrite']}".rpartition(':3306')[0]
    end
    connection = Mysql2::Client.new(:host     => db_creds[:host],
                                    :username => db_creds[:user],
                                    :password => db_creds[:pass],
                                    :flags    => Mysql2::Client::MULTI_STATEMENTS)
    return connection
  else
    # acquire root user credentials from data bag (if specified)
    if rootuser == true
      chef_api_connect.search.query(:mysql, 'id:mysqlserver').rows.each do |db_item|
        db_creds[:user] = db_item['raw_data']['mysqladminuser']
        db_creds[:pass] = db_item['raw_data']['mysqladminpass']
      end
    end
    chef_api_connect.search.query(:environment, "name:#{environment}").rows.each do |envitem|
      # acquire non-root user credentials from environment
      if rootuser == false
        db_creds[:user] = envitem['default_attributes']['af']['activfoundbuser']
        db_creds[:pass] = envitem['default_attributes']['af']['activfoundbpass']
      end
      db_creds[:host]   = envitem['default_attributes']['database']['dbservername']
      db_creds[:schema] = envitem['default_attributes']['fconfig']['founconfigdb']
    end
    fconfig = db_creds[:schema]
    connection = Mysql2::Client.new(:host     => db_creds[:host],
                                    :username => db_creds[:user],
                                    :password => db_creds[:pass],
                                    :flags    => Mysql2::Client::MULTI_STATEMENTS)
    return connection, fconfig
  end
end

# Method returns array of environments marked as hosting tenants
def obtain_tenant_environments
  envs = Array.new
  chef_api_connect.search.query(:environment, 'tenant_environment:*', start: 0).rows.each do |environ|
    if environ['default_attributes']['fconfig']['tenant_environment'] == "true"
      envs << environ['name']
    end
  end
  return envs
end

# Method returns array of all tenants currently in the data bag
def fetch_databag_tenants
  db_tenants = Array.new
  chef_api_connect.search.query(:foundation, '*:*', start: 0).rows.each do |tenant|
    db_tenants << tenant['raw_data']['id']
  end
  return db_tenants
end

# Method returns arrays of tenants and and schema names from fconfig
def fetch_fconfig_tenants
  tenant_fconfig = Array.new
  tenant_envs     = obtain_tenant_environments
  t_name = Array.new
  t_schema = Array.new
  tenant_envs.each do |envname|
    mysql_connect  = mysql_api_connect(envname)
    client         = mysql_connect[0] # mysql connection
    fconfigdb      = mysql_connect[1] # tenant config schema
    results        = client.query("select * from #{fconfigdb}.tenant_config")
    results.each do |row_schema|
      row_schema.each do |col_name, col_val|
        @t_name    = row_schema['tenant_name']
        @t_fconfig = fconfigdb
        @t_env     = envname
      end
      tenant_fconfig << [@t_name, @t_fconfig, @t_env]
    end
  end
  return tenant_fconfig
end

# Method creates/updates foundation data bag tenants across all valid environments
def chef_refresh_tenants
  foundation_bag  = chef_api_connect.data_bags.fetch('foundation')
  current_tenants = fetch_databag_tenants
  tenant_array    = fetch_fconfig_tenants

  # Acqure .feature data bag to whitelist/track features we care about
  feature_bag = Hash.new
  chef_api_connect.search.query('foundation', 'id:.features', start: 0).rows.each do |item|
    feature_bag = item['raw_data']
  end

  tenant_array.each do |t_config|
    tenant        = t_config[0]
    fconfigdb     = t_config[1]
    envname       = t_config[2]
    tenant_bag    = Hash.new
    mysql_connect = mysql_api_connect(envname)
    client        = mysql_connect[0] # mysql connection

    # Acquire contextmode value for tenant attribute
    chef_api_connect.search.query('environment', "name:#{envname}").rows.each do |envitem|
      @contextmode = envitem['default_attributes']['database']['contextmode']
    end

    results = client.query("select * from #{fconfigdb}.tenant_config where tenant_name='#{tenant}'")
    results.each do |row_schema|
      # Set initial tenant attributes from corresponding .tenant_config
      row_schema.each do |col_name, col_val|
        case col_name
        when "tenant_name" 
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
    end

    # Fetch and set additional tenant attributes outside of .tenant_config
    tenant_bag['env'] = envname
    tenant_bag['context'] = @contextmode

    # Queries are combined into multi-statements to reduce query load
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
    
    # Determine whether the tenant should be updated or created
    update_bag = Hash.new
    if current_tenants.include?(tenant)
      puts "(chef_tenant_update): Updating data bag for #{tenant}."
      # Values to retain from existing tenant before updating
      chef_api_connect.search.query('foundation', "id:#{tenant_bag['id']}", start: 0).rows.each do |item|
        tenant_bag['is_provisioned'] = item['raw_data']['is_provisioned']
        tenant_bag['url_alias'] = item['raw_data']['url_alias']
        tenant_bag['tenant_status'] = item['raw_data']['tenant_status']
      end
      update_bag = foundation_bag.items.update(tenant)
      update_bag.data = tenant_bag
    else
      puts "(chef_tenant_update): Creating data bag for #{tenant}."
      update_bag = foundation_bag.items.create(tenant_bag)
    end
    update_bag.save!
  end
end

chef_refresh_tenants
