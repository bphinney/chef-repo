
# Contains methods that associate with api connectivity
module ApiConnect
  # Method acquires chef credentials from user environment knife.rb
  def chef_credentials
    creds = {}
    File.open(ENV['HOME'] + '/.chef/knife.rb').each do |line|
      creds['c_uri']  = line.scan(/'([^']*)'/).join(' ') if line.match('chef_server_url')
      creds['c_key']  = line.scan(/'([^']*)'/).join(' ') if line.match('client_key')
      creds['c_node'] = line.scan(/'([^']*)'/).join(' ') if line.match('node_name')
    end
    return creds
  rescue => e
    logger.error 'Unable to access Chef credentials. Check the knife.rb file for the environment.'
    logger.error "#{e}"
    exit
  end
  module_function :chef_credentials

  # Method connects using chef-api gem and provided credentials
  # Returns Chef Api connection endpoint
  def chef_api_connect
    @tries ||= 0
    # Configured with retries as chef-api occasionally fails on connection
    ChefAPI.log_level = :fatal # Disable the annoying SSL warning messages

    chefcreds = chef_credentials
    ChefAPI::Connection.new(
      client:     chefcreds['c_node'],
      key:        chefcreds['c_key'],
      ssl_verify: false,
      endpoint:   chefcreds['c_uri']
    )
  rescue ChefAPI::Error::HTTPServerUnavailable => e
    api_wait = (@tries += 1)**2
    logger.warn "Chef API is reporting server unavailable, retrying in #{api_wait} seconds"
    logger.warn "#{e}"
    sleep(api_wait)
    retry unless @tries >= 4
  rescue  => e
    api_wait = (@tries += 1)**2
    logger.warn "Chef API is reporting an error, retrying in #{api_wait} seconds"
    logger.warn "#{e}"
    sleep(api_wait)
    retry unless @tries >= 4
  end
  module_function :chef_api_connect

  # Method acquires mysql credentials from either environment or data bag
  # Returns db credentials hash
  def mysql_credentials(environment, rootuser=false)
    db_creds = {}
    # Returns a root only connection if "root" string is defined in lieu of environment
    if environment == "root"
      chef_api_connect.search.query(:mysql, 'id:mysqlserver').rows.each do |db_item|
        db_creds[:user] = db_item['raw_data']['mysqladminuser']
        db_creds[:pass] = db_item['raw_data']['mysqladminpass']
        # Workaround to remove host port concatenation in mysql data bag
        db_creds[:host] = "#{db_item['raw_data']['mysqlwrite']}".rpartition(':3306')[0]
      end
      return db_creds
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
      return db_creds
    end
  end
  module_function :mysql_credentials

  # Method acquires mysql credentials from either environment or data bag
  # Returns connection/schema for environment, or root bypass connection
  def mysql_api_connect(environment, rootuser=false)
    db_creds = {}
    # Returns a root only connection if "root" string is defined in lieu of environment
    if environment == "root"
      chef_api_connect.search.query(:mysql, 'id:mysqlserver').rows.each do |db_item|
        db_creds[:user] = db_item['raw_data']['mysqladminuser']
        db_creds[:pass] = db_item['raw_data']['mysqladminpass']
        # Workaround to remove host port concatenation in mysql data bag
        db_creds[:host] = "#{db_item['raw_data']['mysqlwrite']}".rpartition(':3306')[0]
      end
      connection = Mysql2::Client.new(
        host:     db_creds[:host],
        username: db_creds[:user],
        password: db_creds[:pass],
        flags:    Mysql2::Client::MULTI_STATEMENTS
      )
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
      connection = Mysql2::Client.new(
        host:     db_creds[:host],
        username: db_creds[:user],
        password: db_creds[:pass],
        flags:    Mysql2::Client::MULTI_STATEMENTS
      )
      return connection, fconfig
    end
  end

  # Method acquires aws-sdk api credentials from aws-sdk data bag
  def aws_credentials
    aws_ec2_az = `curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`.strip
    region = aws_ec2_az[0..-2]
    chef_api_connect.search.query('aws-sdk', 'id:main', start: 0).rows.each do |db_item|
      @id  = db_item['raw_data']['aws_access_key_id']
      @key = db_item['raw_data']['aws_secret_access_key']
    end
    awscreds = {
      access_key_id:     @id,
      secret_access_key: @key,
      region:            region
    }
    return awscreds
  end
  module_function :aws_credentials

  # Method connects to a provided aws api class through aws-sdk
  # Returns Aws api connection
  def aws_api_connect(service)
    aws_creds = aws_credentials
    Aws.config.update(aws_creds)
    @tries ||= 0
    # Expandable to include additional aws-sdk api classes as required
    case service
    when 'EC2_Client'     then Aws::EC2::Client.new
    when 'EC2_Resource'   then Aws::EC2::Resource.new
    when 'ELB_Client'     then Aws::ElasticLoadBalancing::Client.new
    when 'Route53_Client' then Aws::Route53::Client.new
    end
  rescue => e
    api_wait = (@tries += 1)**2
    logger.warn "Aws Api is reporting an error, retrying in #{api_wait} seconds"
    logger.warn "#{e}"
    sleep(api_wait)
    retry unless @tries >= 4
   end
  module_function :aws_api_connect

  # Method uses an IAM role to connect to an alternate account/region
  # Returns Aws api connection validated through AWS STS
  def aws_sts_connect(service, iam_arn, iam_session, region)
    aws_creds = aws_credentials
    Aws.config.update(aws_creds)
    @tries ||= 0

    # Returns with secure STS credentials based on provided IAM role
    session = Aws::AssumeRoleCredentials.new(
      client:            Aws::STS::Client.new(aws_creds),
      role_arn:          iam_arn,
      role_session_name: iam_session,
      duration_seconds:  1800
    )

    # Add region to provided credentials (required for route53)
    stscreds = {
      access_key_id:     session.credentials.access_key_id,
      secret_access_key: session.credentials.secret_access_key,
      session_token:     session.credentials.session_token,
      region:            region
    }

    # Expandable to include additional aws-sdk api classes as required
    connection = case service
    when 'Route53_Client' then Aws::Route53::Client.new(stscreds)
    end

    return connection
  rescue Aws::STS::Errors::AccessDenied => e
    logger.fatal("Error: #{e}")
    exit
  rescue => e
    api_wait = (@tries += 1)**2
    logger.warn "Aws STS Api is reporting an error, retrying in #{api_wait} seconds"
    logger.warn "#{e}"
    sleep(api_wait)
    retry unless @tries >= 4
  end
  module_function :aws_sts_connect
end
