#
#  Cookbook Name::   promaws
#  Custom Resource:: security_group
#
#  Copyright 2016, Promethean
#
#  All rights reserved - Do Not Redistribute
#
#  Custom resource that provides Aws Security Group creation 
#  and rule management components
#

include Promaws::ElbListener
include Promaws::Secgroup

# resource_name is an alternative to the cookbook_resourcefile naming pattern
resource_name  :aws_security_group

actions        :create, :add_rule #, :delete, :update
default_action :create

# Properties for security group rules
property :name,     String, name_property: true, required: true
property :type,     String,  default: ''
property :protocol, String,  default: ''
property :port,     String,  default: ''
property :ip_range, String,  default: ''  # CIDR format (0.0.0.0/0)

# Property for security group
property :description, String, default: ''

# Workaround for --why-run Chef Github issue #4537 (https://github.com/chef/chef/issues/4537)
action_class do
  def whyrun_supported?
    true
  end
end

#
#  :create - Creates a baseline empty security group for use with elbs/instances
#
#  aws_security_group 'name' do
#    description 'Foo'
#    action :create
#  end
#
action :create do
  metadata_endpoint       = 'http://169.254.169.254/latest/meta-data/'
  instance_id             = Net::HTTP.get(URI.parse(metadata_endpoint + 'instance-id'))
  vpc_id                  = lookup_vpc_id(instance_id)
  secgroup                = {}
  secgroup['name']        = new_resource.name
  secgroup['vpc_id']      = vpc_id
  secgroup['description'] = new_resource.description
  if security_group_exists(secgroup) == false
    converge_by "Create initial security group #{secgroup['name']}" do
      create_security_group(secgroup)
    end
  end
end

#
#  :add_rule - Sets a security rule for a security group
#              Requires an existing security group
#
#  aws_security_group '<security group name>' do
#    type '<inbound> <outbound>'
#    protocol '<tcp> <udp> <icmp>'
#    port '<80> <1-65535>'                       # Supports a single port or a range
#    source '172.31.0.0/16'                      # CIDR format IP range
#    action :add_rule
#  end
#
action :add_rule do
  secgroup             = {}
  secgroup['name']     = new_resource.name
  secgroup['type']     = new_resource.type
  secgroup['protocol'] = new_resource.protocol.upcase
  secgroup['port']     = new_resource.port
  secgroup['ip_range'] = new_resource.ip_range
  if secgroup_rule_exists(secgroup) == false
    converge_by "Add rule to existing security group #{secgroup['name']}" do
      authorize_security_group_access(secgroup)
    end
  end
end
