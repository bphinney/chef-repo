# Promaws Helpers library
# Contans methods to facilitate internal aws operations

module Promaws
  module Helpers

    class << self
      attr_accessor :requires_region
      attr_accessor :instance_region
    end

    # Method performs a lookup against Aws for an instance's region
    # Used for Aws cookbook v3.1.3 or greater
    def instance_region
      aws_ec2_az = `curl --silent http://169.254.169.254/latest/meta-data/placement/availability-zone`.strip
      region = aws_ec2_az[0..-2]
    end

    # Method provides cookbook version of aws cookbook specifically
    # Required for transition to aws cookbook v3.3.2 or later
    def aws_cookbook_version
       aws_version = run_context.cookbook_collection['aws'].metadata.version.chomp('v')
    end

    # Method determines region requirement based on Aws cookbook modifications
    # Required for transition to aws cookbook v3.3.2 or later
    def requires_region
      aws_vers = aws_cookbook_version
      required = (aws_vers >= '3.3.2') ? true : false
    end


    # Method returns the Aws ID of the instance based on a metadata lookup
    def lookup_instance_id
      metadata_endpoint = 'http://169.254.169.254/latest/meta-data/'
      instance_id = Net::HTTP.get( URI.parse( metadata_endpoint + 'instance-id' ) )
    end
  end
end
