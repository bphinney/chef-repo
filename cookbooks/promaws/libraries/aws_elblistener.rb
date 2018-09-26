module Promaws
  module ElbListener

    require_relative 'aws_apiconnect'
    include Promaws::Apiconnect

    # Method creates a fully functioning load balancer in Aws.
    def create_elastic_load_balancer(elb)
      @tries ||= 0
      secgroup_id = lookup_security_group_details(elb['security_groups'])
      resp        = aws_api_connect('ELB_Client')
      begin
      resp.create_load_balancer({
        load_balancer_name:     elb['name'],               # required
        listeners: [
          {
            protocol:           elb['protocol'],           # required
            load_balancer_port: elb['port'],               # required
            instance_protocol:  elb['instance_protocol'],
            instance_port:      elb['instance_port'],      # required
            ssl_certificate_id: elb['ssl_cert'],           # optional
          },
        ],
        subnets:                elb['subnets'],
        security_groups:        secgroup_id,
       })
      rescue Aws::ElasticLoadBalancing::Errors::DuplicateLoadBalancerName
        Chef::Log.info "Load Balancer #{elb['name']} already exists, bypassing"
      rescue Aws::ElasticLoadBalancing::Errors::Throttling
        api_wait = (@tries += 1)**2
        Chef::Log.warn 'Aws is reporting a connection throttle, retrying...'
        sleep(api_wait)
        retry unless @tries >= 4
      end
    end

    # Method tests for an existing elb by checking for associated attributes
    # Returns true/false
    def elastic_load_balancer_exists(elb)
      resp    = aws_api_connect('ELB_Client')
      elb_key = resp.describe_load_balancer_attributes({
        load_balancer_name: elb['name'],
      }).load_balancer_attributes
      !elb_key.nil? ? true : false
    rescue Aws::ElasticLoadBalancing::Errors::LoadBalancerNotFound
      return false
    end

    # Method adds a listener to an existing load balancer.
    def add_elb_listener(elb)
      @tries ||= 0
      resp = aws_api_connect('ELB_Client')
      begin
      resp.create_load_balancer_listeners({
        load_balancer_name:     elb['name'],
        listeners: [
          {
            protocol:           elb['protocol'],
            load_balancer_port: elb['port'],
            instance_protocol:  elb['instnace_protocol'],
            instance_port:      elb['instance_port'],
            ssl_certificate_id: elb['ssl_cert'],
          },
        ],
      })
      rescue Aws::ElasticLoadBalancing::Errors::DuplicateListener
        Chef::Log.info "Load Balancer listener #{elb['name']} duplicate exists, skipping"
      rescue Aws::ElasticLoadBalancing::Errors::Throttling
        api_wait = (@tries += 1)**2
        Chef::Log.warn 'Aws is reporting a connection throttle, retrying...'
        sleep(api_wait)
        retry unless @tries >= 4
      end
    end

    # Method packs listener rule into string for fast evaluation
    # Utilizes protocol, port range, and source.
    # Returns String of packed listener rule paremeters.
    # Ex: https-443-https-80
    def pack_listener_rule(listener)
      ip = "#{listener['protocol']}".downcase
      fp = "#{listener['port']}"
      tp = "#{listener['instance_protocol']}".downcase
      ir = "#{listener['instance_port']}"
      pack_rule = ip + "-" + fp + "-" + tp + "-" + ir
      return pack_rule
    end

    # Method compares current listener to listeners attached to specified elb
    # Returns true/false
    def elb_listener_exists(elb)
      list_set  = []
      resp      = aws_api_connect('ELB_Client')
      instances = resp.describe_load_balancers({
        load_balancer_names: [elb['name']],
      }).each do |lb|
        lb['load_balancer_descriptions'].each do |ld|
          ld['listener_descriptions'].each do |list|
            match = ''
            list.listener.to_h.map do|k,v|
              case ["#{k}"][0]
              when 'protocol'           then match += "#{v}".downcase + "-"
              when 'load_balancer_port' then match += "#{v}" + "-"
              when 'instance_protocol'  then match += "#{v}".downcase + "-"
              when 'instance_port'      then match += "#{v}"
              end
            end
            list_set << match
          end
        end
      end
      current_rule = pack_listener_rule(elb)
      list_set.include?(current_rule) ? true : false
    rescue Aws::ElasticLoadBalancing::Errors::LoadBalancerNotFound => e
      Chef::Log.info "#{e}"
      return false
    end

    # Method indicates whether an instance is attached to a specified elb
    # Returns true/false
    # TODO: Ensure this works with multiple instances
    def instance_registered_to_elb(elb)
      resp      = aws_api_connect('ELB_Client')
      instances = resp.describe_load_balancers({
        load_balancer_names: [elb['name']],
      }).load_balancer_descriptions[0].instances
      instances.each_with_index do |id, index|
        if id[index] == elb['instance_id']
          return true
        end
      end
      return false
    end

    # Method registers the instance with the specified load balancer by name
    def register_instance_to_elb(elb)
      resp = aws_api_connect('ELB_Client')
      resp.register_instances_with_load_balancer({
        load_balancer_name: elb['name'],
        instances: [
          {
            instance_id: elb['instance_id'],
          },
        ],
      })
    end

    # Method removes the instance from the specified elb by name
    def deregister_instance_from_elb(elb)
      resp = aws_api_connect('ELB_Client')
      resp.deregister_instances_from_load_balancer({
        load_balancer_name: elb['name'],
        instances: [
          {
            instance_id: elb['instance_id'],
          },
        ],
      })
    end

    # Method returns the vpc_id based on location of the instance
    def lookup_vpc_id(instance_id)
      resp   = aws_api_connect('EC2_Client')
      vpc_id = resp.describe_instances({
        instance_ids: [instance_id],
      }).reservations[0].instances[0].network_interfaces[0].vpc_id
      return vpc_id
    end

    # Method returns an array of secgroup ids for multiple security groups
    def lookup_security_group_details(groups)
      secgroup_ids = []
      connect      = aws_api_connect('EC2_Client')
      groups.each do |group|
        begin
        secgroup_id = connect.describe_security_groups({
           filters: [
            {
              name:   'group-name',
              values: [group],
            },
          ],
        }).security_groups[0].group_id
        secgroup_ids << secgroup_id
        rescue
          Chef::Log.warn "No security group by the name #{group} found"
        end
      end
      return secgroup_ids
    end

    # Method checks whether a security group exists by name
    # Returns true/false
    def security_group_exists(secgroup)
      connect     = aws_api_connect('EC2_Client')
      secgroup_id = connect.describe_security_groups({
         filters: [
          {
            name:   'group-name',
            values: [secgroup['name']],
          },
        ],
      }).security_groups[0].group_id
      !secgroup_id.empty? ? true : false
    rescue NoMethodError
      return false
    rescue ArgumentError
      return false
    end

    # Method checks whether a security group exists by name
    # Returns true/false
    # TODO: Find means to merge with above
    def get_secgroup_id(secgroup)
      connect     = aws_api_connect('EC2_Client')
      secgroup_id = connect.describe_security_groups({
         filters: [
          {
            name:   'group-name',
            values: [secgroup['name']],
          },
        ],
      }).security_groups[0].group_id
      if !secgroup_id.empty?
        return secgroup_id
      else 
        return false
      end
    rescue NoMethodError => e
      return false
    rescue ArgumentError => e
      return false
    end

    # Method returns a valid subnet id based on provided subnet name
    # Returns array
    def lookup_instance_subnet
      subnet             = []
      metadata_endpoint  = 'http://169.254.169.254/latest/meta-data/'
      instance_id        = Net::HTTP.get(URI.parse(metadata_endpoint + 'instance-id'))
      connect            = aws_api_connect('EC2_Client')
      subnet_id          = connect.describe_instances({
        instance_ids: ["#{instance_id}"],
      }).reservations[0].instances[0].subnet_id
      subnet << subnet_id
      return subnet
    end

    # Method creates secgroup
    # Returns secgroup id for existing secgroup or on created
    def create_security_group(secgroup)
      resp  = aws_api_connect('EC2_Resource')
      group = resp.create_security_group({
        group_name:  secgroup['name'],        # required
        description: secgroup['description'], # required
        vpc_id:      secgroup['vpc_id'],      # required
      })
      secgroup_id = group.id
      Chef::Log.info "Created secgroup id #{secgroup['name']} with id #{secgroup_id}."
    end
  end
end


