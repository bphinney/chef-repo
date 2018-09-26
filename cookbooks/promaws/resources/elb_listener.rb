#
#  Cookbook Name::   promaws
#  Custom Resource:: elb_listener
#
#  Copyright 2016, Promethean
#
#  All rights reserved - Do Not Redistribute
#
#  Custom resource that provides Aws Elb creation and management components
#

include Promaws::ElbListener
include Promaws::Helpers

# resource_name is an alternative to the cookbook_resourcefile naming pattern
resource_name  :aws_elb_listener

# TODO:
# delete - remove elb
# purge  - remove listeners
actions        :create, :register, :reset#, :delete, :purge, :reset, :nothing
default_action :register

# Elb Name
property :name,            String, name_property: true, required: true
# '<protocol>,<port>'
property :external_port,   String
# '<protocol>,<port>'
property :internal_port,   String
# Optional, defaults to instance subnet
property :subnets,         Array,  default: []
# Minimum one required
property :security_groups, Array,  default: []
# Required for https/ssl
property :ssl_cert,        String

action_class do
  # Workaround for --why-run Chef Github issue #4537 (https://github.com/chef/chef/issues/4537)
  def whyrun_supported?
    true
  end

  def lookup_elb_resources
    elb = {}
    elb['name']              = new_resource.name
    elb['protocol']          = new_resource.external_port.split(':')[0].upcase
    elb['port']              = new_resource.external_port.split(':')[1].to_i
    elb['instance_protocol'] = new_resource.internal_port.split(':')[0].upcase
    elb['instance_port']     = new_resource.internal_port.split(':')[1].to_i
    elb['security_groups']   = new_resource.security_groups

    # Configure default subnet internally if not specified as part of the resource
    if new_resource.subnets.empty?
      elb['subnets'] = lookup_instance_subnet
    else
      elb['subnets'] = new_resource.subnets
    end

    # Pass in ssl arn if provided (required for external https/ssl termination)
    if !ssl_cert.nil?
      aws_region      = instance_region
      aws_account     = data_bag_item("aws-sdk", "main")['aws_account'] 
      ssl_cert_name   = new_resource.ssl_cert if new_resource.ssl_cert
      elb['ssl_cert'] = "arn:aws:acm:#{aws_region}:#{aws_account}:certificate/#{ssl_cert_name}"
      # TODO: Provide both acm and arn cert support
      #elb['ssl_cert'] = "arn:aws:arn::#{aws_account}:server-certificate/#{ssl_cert_name}" 
    end
    return elb
  end
end

#
# :create - Adds an elb listener to an elastic load balancer or or creates 
#           one if one does not exist.
#
# aws_elb_listener 'elb_name' do
#   external_port 'https:443'        # <http> <https> <tcp> <ssl>:port
#   internal_port 'http:80'          # <http> <https> <tcp> <ssl>:port
#   subnets ['<subnets>']            # Array, optional, will default to instance
#   security_groups ['http-https']   # Array, minimum one required
#   ssl_cert: <aws certificate name> # required for https/ssl termination
#   action :create
# end
#
action :create do
  elb = lookup_elb_resources 
  # Add a listener to an elb, or creates it if it does not exist 
  if elastic_load_balancer_exists(elb) == false
    converge_by "Create initial elastic load balancer #{elb['name']}" do
      create_elastic_load_balancer(elb)
    end
  end
  if elb_listener_exists(elb) == false
    converge_by "Add listener for elastic load balancer #{elb['name']}" do
      add_elb_listener(elb)
    end
  end
end


#
# :register - registers instance to elastic load balancer
#
# aws_elb_listener 'elb_name' do
#   action :register
# end
#
action :register do
  elb                = {}
  elb['name']        = new_resource.name
  # Instance id lookup
  metadata_endpoint  = 'http://169.254.169.254/latest/meta-data/'
  elb['instance_id'] = Net::HTTP.get(URI.parse(metadata_endpoint + 'instance-id'))
  if elastic_load_balancer_exists(elb) == true
    if instance_registered_to_elb(elb) == false
      converge_by "Register instance to elb #{elb['name']}" do
        register_instance_to_elb(elb)
      end
    end
  end
end

#
# :reset - unsets and resets an instance to an elb to force clean status
#          Will also reregister an unregistered instance back to an elb
#
# aws_elb_listener 'elb_name' do
#   action :reset
# end
#
action :reset do
  elb                = {}
  elb['name']        = new_resource.name
  metadata_endpoint  = 'http://169.254.169.254/latest/meta-data/'
  elb['instance_id'] = Net::HTTP.get(URI.parse(metadata_endpoint + 'instance-id'))
  if elastic_load_balancer_exists(elb) == true
    # deregister and reregister
    if instance_registered_to_elb(elb) == true
      converge_by "Reset instance with elb #{elb['name']}" do
        deregister_instance_from_elb(elb)
        sleep(3)
        register_instance_to_elb(elb)
      end
    # register back to elb if removed by other means
    else instance_registered_to_elb(elb) == false
      converge_by "Register instance to elb #{elb['name']}" do
        register_instance_to_elb(elb)
      end
    end
  end
end
