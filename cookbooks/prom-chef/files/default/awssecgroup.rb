###########################################
# Amazon Aws Ec2 Security Group Functions #
###########################################

# Extracts a list of IPs from the provded security group in Aws
def aws_secgroup_list( secgroup )
  sec_list = []
  filtered_group = $aws.describe_security_groups({
    filters: [
      {
        name: "group-name",
        values: [secgroup],
      },
    ],
  })
  filtered_group.each do |sgroup|
    sgroup["security_groups"].each do |perms|
      perms["ip_permissions"].each do |lists|
       lists["ip_ranges"].each do |range|
         # Remove IP range - assuming all whitelisted ips are /32.
         sec_list << range["cidr_ip"].split("/")[0]
       end
      end
    end
  end
  return sec_list.sort.uniq
end

# Adds CIDR-based IP range/ports to the defined Aws EC2 Security group.
def authorize_security_group_access( sec_group_name, ip_addr, port )

  sec_group_id = $aws.describe_security_groups({
    filters: [
        {
          name: "group-name",
          values: [sec_group_name],
        },
      ],
    }).security_groups[0].group_id

  $aws.authorize_security_group_ingress({
    group_id: sec_group_id, # Must use Group Id for authorization
    ip_permissions: [
      {
        ip_protocol: "tcp",
        from_port: port,
        to_port: port,
        ip_ranges: [
          {
            cidr_ip: "#{ip_addr}/32",
          },
        ],
      },
    ],
  })
end


# Adds CIDR-based IP range/ports to the defined Aws EC2 Security group.
def revoke_security_group_access( sec_group_name, ip_addr, port )
  sec_group_id = $aws.describe_security_groups({
    filters: [
        {
          name: "group-name",
          values: [sec_group_name],
        },
      ],
    }).security_groups[0].group_id

  $aws.revoke_security_group_ingress({
    group_id: sec_group_id, # Must use Group Id for revoke
    ip_permissions: [
      {
        ip_protocol: "tcp",
        from_port: port,
        to_port: port,
        ip_ranges: [
          {
            cidr_ip: "#{ip_addr}/32",
          },
        ],
      },
    ],
  })
end

# Accesses, filters, and updates Aws security group based on specified JIRA IP list resource.
def aws_filter(groupname, listpage, portlist)
  cur_list = aws_secgroup_list(groupname)
  ip_list = `curl --silent --user administrator:N3wPr0m3the4n1 -G https://wiki.prometheanjira.com/display/OP/#{listpage}`.gsub(/<\/?(span|label)>/, "").scan(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/).uniq

  if ip_list.count > 1 then
    ( cur_list - ip_list ).each do |iplist|
      if iplist != '0.0.0.0'
        portlist.each do |port|
          puts "Revoking IP #{iplist} for port #{port} for EC2 security group #{groupname}"
          revoke_security_group_access( groupname, iplist, port )
          sleep(1)
        end
      end
    end
    ( ip_list - cur_list ).each do |iplist|
       portlist.each do |port|
         puts "Authorizing IP #{iplist} for port #{port} for EC2 security group #{groupname}"
         authorize_security_group_access( groupname, iplist, port )
         sleep(1)
       end
    end
  end
end


