#########################################
# Amazon Aws Ec2 Security Group Methods #
#########################################

module Promaws
  module Secgroup

    require_relative 'aws_apiconnect'
    include Promaws::Apiconnect

    # Method intelligently parses single ports or ip ranges to provide
    # a 'from_port' and 'to_port' typically required for Aws api calls
    # Returns array. Assumes ranges are single values (80) or port range
    # separated by hyphen (1-65535).
    def port_parse(port_range)
      parsed_ports = []
      if port_range.include?('-')
        from_port    = port_range.split('-')[0]
        to_port      = port_range.split('-')[1]
        parsed_ports = [from_port, to_port]
      else
        parsed_ports = [port_range, port_range]
      end
      return parsed_ports
    end

    # Method packs secgroup rule into string for fast evaluation
    # Utilizes protocol, port range, and source. 
    # Returns String of packed secgroup rule paremeters. 
    # Ex: tcp-80-80-172.31.0.0/16
    def pack_secgroup_rule(secgroup)
      port_range = port_parse(secgroup['port'])
      ip = "#{secgroup['protocol']}".downcase
      fp = "#{port_range[0]}"
      tp = "#{port_range[1]}"
      ir = "#{secgroup['ip_range']}"
      pack_rule = ip + "-" + fp + "-" + tp + "-" + ir
      return pack_rule
    end

    # Method compares current rule to one in security group
    # Returns true/false. Expects a validated security group id
    def secgroup_rule_exists(secgroup)
      rule_set    = []
      secgroup_id = lookup_security_group_id(secgroup)
      if secgroup_id.nil?
        return false
      end

      # I could find no good means of checking existence without checking every
      # component of every rule. To work around this, I turn each rule into a
      # string of relevant values, then perform a comparison.
      resp = aws_api_connect('EC2_Client')
      resp.describe_security_groups({
        group_ids: [secgroup_id],
      }).each do |sgroup|
        sgroup["security_groups"].each do |perms|
          perms['ip_permissions'].each do |rule|
            # This produces the same rule string as pack_secgroup_rule, but this
            # needs to work through the Aws api struct and also filter out 
            # unnecessary components. Ex: tcp-80-80-172.31.0.0/16
            match = ''
              rule.to_h.map do|k,v| 
                case ["#{k}"][0]
                when 'ip_protocol' then match += "#{v}".downcase + "-"
                when 'from_port'   then match += "#{v}" + "-"
                when 'to_port'     then match += "#{v}" + "-"
                when 'ip_ranges'   then v[0].map{|i,j| match += "#{j}"}
                end
              end
            rule_set << match
          end
        end
      end
      # Check the provided rule against the secgroup rules 
      current_rule = pack_secgroup_rule(secgroup)
      rule_set.include?(current_rule) ? true : false
    end

    # Method checks whether a security group exists by name
    # NOTE: Temporary duplicate
    def lookup_security_group_id(secgroup)
      secgroup_name = secgroup['name']
      connect       = aws_api_connect('EC2_Client')
      secgroup_id   = connect.describe_security_groups({
        filters: [
          {
            name:   'group-name',
            values: [secgroup_name],
          },
        ],
      }).security_groups[0].group_id
      return secgroup_id
    rescue NoMethodError
      return nil
    rescue ArgumentError
      return nil
    end

    # Adds CIDR-based IP range/ports to the defined Aws EC2 Security group.
    def authorize_security_group_access(secgroup)
      @tries ||= 0
      
      port_range = port_parse(secgroup['port'])
      # Aws references 'ingress' and 'eagress' in secgroup methods.
      # This simplifies it to just inbound/outbound per the console
      # and dynamically modfies the method
      access_type = case secgroup['type']
        when 'inbound'  then 'ingress'
        when 'outbound' then 'eagress'
      end
      sec_group_id = lookup_security_group_id(secgroup)
      connect      = aws_api_connect('EC2_Client')
      connect.method("authorize_security_group_#{access_type}").call({
        group_id:        sec_group_id, # required
        ip_permissions: [
          {
            ip_protocol: secgroup['protocol'],
            from_port:   port_range[0],
            to_port:     port_range[1],
            ip_ranges: [
              {
                cidr_ip: "#{secgroup['ip_range']}",
              },
            ],
          },
        ],
      })
    rescue Aws::EC2::Errors::InvalidPermissionDuplicate
      Chef::Log.warn "Ingress rule allow #{port} for #{group['sec_protocol']} exists, skipping."
    rescue Aws::EC2::Errors::RequestLimitExceeded
      api_wait = (@tries += 1)**2
      Chef::Log.warn 'Aws is reporting request limit exceeded, retrying...'
      sleep(api_wait)
      retry unless @tries >= 4
    rescue Aws::EC2::Errors::MissingParameter
      api_wait = (@tries += 1)**2
      Chef::Log.warn 'Aws is reporting a missing param, retrying...'
      sleep(api_wait)
      retry unless @tries >= 4
    end

    # Adds CIDR-based IP range/ports to the defined Aws EC2 Security group.
    def revoke_security_group_access( sec_group_name, ip_addr, port )
      @tries ||= 0
      port_range   = port_parse(secgroup['port'])
      connect      = aws_api_connect('EC2_Client')
      sec_group_id = lookup_security_group_id(secgroup)
      connect.revoke_security_group_ingress({
        group_id: sec_group_id, # required
        ip_permissions: [
          {
            ip_protocol: secgroup['protocol'],
            from_port:   port_range[0],
            to_port:     port_range[1],
            ip_ranges: [
              {
                cidr_ip: "#{secgroup['ip_range']}",
              },
            ],
          },
        ],
      })
    rescue Aws::EC2::Errors::InvalidPermissionDuplicate
      Chef::Log.warn "Ingress rule allow #{port} for #{group['sec_protocol']} exists, skipping."
    rescue Aws::EC2::Errors::RequestLimitExceeded
      api_wait = (@tries += 1)**2
      Chef::Log.warn 'Aws is reporting request limit exceeded, retrying...'
      sleep(api_wait)
      retry unless @tries >= 4
    end
  end
end
