require_relative 'apiconnect'

class BootStrap
  include ApiConnect

  # Method checks to see if the named node/client exists
  def node_existence_check(node_name)
    chef_api_connect.search.query('node', "name:#{node_name}", start: 0).rows.each do |node|
      if node.nil?
        next
      else
        logger.info("Node \"#{node_name}\" already exists, exiting..")
        exit
      end
    end
    chef_api_connect.search.query('client', "name:#{node_name}", start: 0).rows.each do |node|
      if node.nil?
        next
      else
        logger.fatal("Client \"#{node_name}\" already exists, exiting..")
        exit
      end
    end
  end

  # Method acquires recipes from role only - not used currently
  def fetch_run_list_by_role(role)
    chef_api_connect.search.query('role', "name:#{role}", start: 0).rows.each do |role|
      @run_list = role['run_list']
    end
    if @run_list.nil?
      logger.fatal("Role \"#{role}\" not found, exiting..")
      exit
    end
    # Concatenates results to string to pass to bootstrap command
    run_list = @run_list.join(',')
    return run_list
  end

  # Method extracts default values for the datacenter as defined by the local data bag
  def fetch_bootstrap_defaults
    bdefs = Hash.new
    chef_api_connect.search.query('aws-sdk', 'id:bootstrap', start: 0).rows.each do |boot_item|
      bdefs['cfg_ami']       = boot_item['raw_data']['default_ami']
      bdefs['secgroup']      = boot_item['raw_data']['default_secgroup']
      bdefs['av_zone']       = boot_item['raw_data']['default_av_zone']
      bdefs['instance_type'] = boot_item['raw_data']['default_instance']       
      bdefs['base_subnet']   = boot_item['raw_data']['default_subnet']
    end
    return bdefs
  end

  # Initiates creation of generic Aws instance for bootstrapping
  def create_instance(instance)
    node_name     = instance['node_name']
    secgroup      = instance['secgroup']
    av_zone       = instance['av_zone']
    base_subnet   = instance['base_subnet']
    term_protect  = instance['secure']
    # Override for default size
    if !instance['size'].nil?
      instance_type = instance['size']
    else
      instance_type = instance['instance_type']
    end

    # Override for ami
    if !instance['ami'].nil?
      cfg_ami = instance['ami']
    else
      cfg_ami = instance['cfg_ami']
    end

    connect = aws_api_connect('EC2_Resource')
    begin
      dest = connect.create_instances({
        :image_id => "#{cfg_ami}", # required
        :min_count => 1,           # required
        :max_count => 1,           # required
        :security_group_ids => [secgroup],
        :placement => {
          :availability_zone => "#{av_zone}",
        },
        :instance_type => "#{instance_type}",
        :disable_api_termination => "#{term_protect}",
        :instance_initiated_shutdown_behavior => 'stop',
        :subnet_id => "#{base_subnet}",
        :key_name => "ngroot",
        :monitoring => {
          :enabled => false, # required
        }
      })
    rescue Aws::EC2::Errors::InstanceLimitExceeded => e
      logger.error("Error: #{e}")
      abort
    end

    # Extract useful info from Instance Resource
    destid = dest.map(&:id)[0]
    destip = dest.map(&:private_ip_address)[0]

    # Names the instance in the Aws console
    begin
    dest.batch_create_tags({
      :resources => ["#{destid}"],
      :tags => [
        {
          :key => "Name",
          :value => "#{node_name}",
        },
      ],
    })
    rescue NoMethodError => e
    # Older create_tags method fallback for older Apis (China)
    logger.warn "Falling back to old Aws api for tag creation"
    dest.create_tags({
      :resources => ["#{destid}"],
      :tags => [
        {
          :key => "Name",
          :value => "#{node_name}",
        },
      ],
    })   
    end

    # Initiate post-instance waiter
    begin
      wait = aws_api_connect('EC2_Client')
      logger.info("Instance #{destid} at #{destip} is now being created.")
      logger.info("Waiting for aws to report status ok...")
      wait.wait_until(:instance_status_ok, instance_ids:[destid])
    rescue Aws::Waiters::Errors::WaiterFailed => e
      logger.fatal("Wait failed, please check the instance stats in the Aws console.\n#{e}")
      abort
    end
    return destip
  end

  # Method performs complete knife bootstrap command on remote node.
  def bootstrap_node(destip, bnode)
    # Loop reinitates entire bootstrap on failure/retry
    loop do
      node         = bnode['node_name']
      role         = bnode['role']
      node_env     = bnode['node_env']

      bootstrap = "knife bootstrap #{destip} " +
                  # Required name for node/hostname
                  "--node-name #{node} " +
                  # Run list set to specified role
                  "--run-list \'role[#{role}]\' " +
                  # Required environment
                  "--environment #{node_env} " +
                  # Not using ssl
                  "--node-ssl-verify-mode none " +
                  # Prevent clobbering into old known_hosts
                  "--no-host-key-verify " +
                  # Ensures first-deploy operations
                  "--bootstrap-install-command \"export FIRST_DEPLOY=\"1\"\" " +
                  # Configure initial hostname required by chef-client
                  "--bootstrap-install-command \"hostname #{node}\" " +
                  # Default bootstrapping operations
                  "--bootstrap-template \"chef-full\" " +
                  # .pem file for ssh
                  "--secret-file \"/root/.ssh/ngroot.pem\""

      bootstrap_status = system(bootstrap)
      if !bootstrap_status
        choose do |menu|
          logger.error("chef-client run reports failure for node #{node}.")
          menu.prompt = "Retry?"
          menu.choice('retry') { next }
          menu.choice('exit')  { exit }
        end
      else
        logger.info("SUCCESS: chef-client run reports success.")
        break
      end
    end
  end
end
