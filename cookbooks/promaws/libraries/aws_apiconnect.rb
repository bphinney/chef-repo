
module Promaws
  module Apiconnect

    # Method acquires aws-sdk api credentials from aws-sdk data bag
    def aws_credentials
      aws_ec2_az = `curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`.strip
      region     = aws_ec2_az[0..-2]
      awsdata    = data_bag_item("aws-sdk", "main")
      awscreds   = {
        :access_key_id     => awsdata['aws_access_key_id'],
        :secret_access_key => awsdata['aws_secret_access_key'],
        :region            => region
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
      when 'EC2_Secgroup'   then Aws::EC2::SecurityGroup.new
      when 'ELB_Client'     then Aws::ElasticLoadBalancing::Client.new
      when 'Route53_Client' then Aws::Route53::Client.new
      end
    rescue => e
      api_wait = (@tries += 1)**2
      Chef::Log.warn "Aws Api is reporting an error, retrying in #{api_wait} seconds"
      Chef::Log.warn "#{e}"
      sleep(api_wait)
      retry unless @tries >= 4
     end
     module_function :aws_api_connect
  end
end
