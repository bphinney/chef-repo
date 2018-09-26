class Datacenter
  include ApiConnect

  # Method creates a fully functioning load balancer in Aws.
  def create_elb(elb)
    resp = aws_api_connect("ELB_Client")
    begin
    pants = resp.create_load_balancer({
      load_balancer_name: elb[:name],
      listeners: [
        {
          protocol: elb[:protocol],
          load_balancer_port: elb[:port],
          instance_protocol: elb[:instnace_protocol],
          instance_port: elb[:instance_port],
          ssl_certificate_id: elb[:ssl_cert],
        },
      ],
      subnets: elb[:subnets],
      security_groups: elb[:security_groups],
    })
    rescue Aws::ElasticLoadBalancing::Errors::DuplicateLoadBalancerName
      puts "Load Balancer #{elb[:name]} already exists, bypassing"
    rescue Aws::ElasticLoadBalancing::Errors::Throttling
      puts "api throttled, retrying"
      # TODO: Add exponential backoff
      sleep(5)
      retry
    end
  end

  # Method adds a listener to an existing load balancer.
  def elb_listener(elb)
    resp = aws_api_connect("ELB_Client")
    begin
    pants = resp.create_load_balancer_listeners({
      load_balancer_name: elb[:name],
      listeners: [
        {
          protocol: elb[:protocol],
          load_balancer_port: elb[:port],
          instance_protocol: elb[:instnace_protocol],
          instance_port: elb[:instance_port],
          ssl_certificate_id: elb[:ssl_cert],
        },
      ],
    })
    rescue Aws::ElasticLoadBalancing::Errors::DuplicateListener
      puts "Load Balancer listener #{elb[:name]} duplicate exists, skipping"
    end
  end

  # Method creates secgroup
  # Returns secgroup id for existing secgroup or on created
  def create_secgroup(group)
    connect = aws_api_connect('EC2_Client')
    begin
    p group[:name]
    sec_id = connect.describe_security_groups({
      filters: [
        {
          name: "group-name",
          values: [group[:name]],
        },
      ],
    }).security_groups[0].group_id
    return sec_id
    rescue => e
      not_created = true
    end

    if not_created == true
      resp = aws_api_connect("EC2_Resource")
      pants = resp.create_security_group({
        group_name: group[:name],   # required
        description: group[:description], # required
        vpc_id: group[:vpc_id],
      })
      secgroup_id = pants.id
      puts "Created secgroup id #{group[:name]} with id #{secgroup_id}."
      return secgroup_id
    end
  end

  def ingress_secgroup(secgroup_id, group)
    ban = aws_api_connect("EC2_Client")
    group[:sec_port].each do |port|
      begin
      ban.authorize_security_group_ingress({
        group_id: secgroup_id, # Must use Group Id for authorization
        ip_permissions: [
          {
            ip_protocol: group[:sec_protocol],
            from_port: port,
            to_port:  port,
            ip_ranges: [
              {
                cidr_ip: "#{group[:ip_range][0]}/#{group[:ip_range][1]}",
              },
            ],
          },
        ],
      })
      rescue Aws::EC2::Errors::InvalidPermissionDuplicate
        puts "Ingress rule allow #{port} for #{group[:sec_protocol]} exists, skipping."
      rescue Aws::EC2::Errors::RequestLimitExceeded
        puts "api request limit exceeded, retrying"
        sleep(5)
        retry
      end
    end
  end
end



