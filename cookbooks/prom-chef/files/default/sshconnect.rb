

module SSHConnect

  require 'net/ssh'
  require 'net/scp'

  # Method executes ssh command, returns array of associated outpuds and exit codes
  def ssh_exec!(ssh, command)
    stdout_data = ""
    stderr_data = ""
    exit_code   = nil
    exit_signal = nil
    ssh.open_channel do |channel|
      channel.exec(command) do |ch, success|
        unless success
          abort "FAILED: couldn't execute command (ssh.channel.exec)"
        end
        channel.on_data do |ch,data|
          stdout_data += data
        end
        channel.on_extended_data do |ch,type,data|
          stderr_data += data
        end
        channel.on_request("exit-status") do |ch,data|
          exit_code   = data.read_long
        end
        channel.on_request("exit-signal") do |ch, data|
          exit_signal = data.read_long
        end
      end
    end
    ssh.loop
    return [stdout_data, stderr_data, exit_code, exit_signal]
  end
  module_function :ssh_exec!

  # Method performs a remote ssh command on a host
  # Returns output array based on ssh_exec! method results
  # expects ngroot.pem file to be available on the instance
  def run_ssh_command(host, command)
    keys   = ['~/.ssh/ngroot.pem']
    config = '/etc/ssh/ssh_config'
    user   = 'root'
    Net::SSH.start(
                   host, user,
                   :keys      => keys,
                   :config    => config,
                   :keys_only => true,
                   #:verbose  => :debug,
                   :paranoid  => false
    ) do |ssh|
      command = ssh_exec!(ssh, command)
      return command
    end
  end
  module_function :run_ssh_command

  # Method transfers a directory or file from a remote host to local
  # expects ngroot.pem file to be available on the instance
  def ssh_copy_item(host, remote_path, local_path, item='file')
    keys   = ['~/.ssh/ngroot.pem']
    config = '/etc/ssh/ssh_config'
    user   = 'root'
    Net::SSH.start(
                   host, user,
                   :keys      => keys,
                   :config    => config,
                   :keys_only => true,
                   #:verbose  => :debug,
                   :paranoid  => false
    ) do |ssh|
      begin
      if item == 'file'
        command = ssh.scp.download!( remote_path, local_path )
      elsif item == 'directory'
        command = ssh.scp.download!( remote_path, local_path, :recursive => true )
      else
        puts "item must be either 'file' or 'directory'"
        exit
      end
      return command
      rescue Net::SCP::Error => e
        puts "ERROR: Unable to copy item due to the following:"
        puts "#{e}"
      end
    end
  end
  module_function :ssh_copy_item


  # Method performs direct ssh command on a host
  # Returns block output to screen
  # expects ngroot.pem file to be available on the instance
  def run_command_manual(host, command)
     `ssh -i ~/.ssh/ngroot.pem -o StrictHostKeyChecking=false root@#{host} #{command}`
  end
  module_function :run_command_manual

  # Method runs command through 'knife ssh' where knife is installed
  def run_command_knife(node, command)
    `sudo knife ssh 'name:#{node}' '#{command}'`
  end
end
