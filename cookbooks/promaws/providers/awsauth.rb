def whyrun_supported?
  true
end

action :connect do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } already connected to AWS."
  else
    converge_by("Create #{ @new_resource }") do
      connect_aws 
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::PromawsAwsauth.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
end


def connect_aws
 
  get_region = %x[wget -q --no-check-certificate -O - http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk '{print $3}'].scan(/"(.*)"/)
  aws_ec2_region = get_region.join
  Chef::Log.info("AWS EC2 Region is: #{aws_ec2_region}")

  awsdata = data_bag_item("aws-sdk", "main")
  ##Log "aws_access_key_id: #{awsdata['aws_access_key_id']}"
  ##Log "aws_secret_access_key: #{awsdata['aws_secret_access_key']}"
  ##Log "aws_region: #{aws_ec2_region}" 
  awscreds = {
    :access_key_id    => awsdata['aws_access_key_id'],
    :secret_access_key => awsdata['aws_secret_access_key'],
    :region           => aws_ec2_region
  }
  AWS.config(awscreds)

  ec2 = AWS::EC2.new
  elb = AWS::ELB.new

  # List of AWS Availability Zones for account
  node.normal['awssdk']['av_zones'] = ec2.availability_zones.map(&:name) 
    ##Log "DEBUG: Availability Zones List: #{node[:awssdk][:av_zones]}"

  # List AWS Availability Zone for instance
  node.normal['awssdk']['av_zone'] = `curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
    ##Log "DEBUG: Instance AV-Zone: #{node[:awssdk][:av_zone]}" 

  # List of AWS Regions for account
  node.normal['awssdk']['regions'] = ec2.regions.map(&:name) 
    ##Log "DEBUG: Region List: #{node[:awssdk][:regions]}" 

  # List of AWS Region for instance
  #node.normal['awssdk']['region'] = ec2.availability_zones.map(&:region_name).uniq
  node.normal['awssdk']['region'] = ec2.availability_zones.map(&:region_name).uniq
    ##Log "DEBUG: Instance Region: #{node[:awssdk][:region]}"

  # Returns instance id
  metadata_fetch_1 = 'http://169.254.169.254/latest/meta-data/'
  node.normal['awssdk']['instance_id'] = Net::HTTP.get( URI.parse( metadata_fetch_1 + 'instance-id' ) )
    ##Log "DEBUG: Instance ID: #{node[:awssdk][:instance_id]}" 
end

