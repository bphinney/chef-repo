include Chef::Mixin::ShellOut

use_inline_resources

def info(msg)
  Chef::Log.info("firewall[#{@new_resource.name}] #{msg}")
end

# With all actions, we can't assume anything from the start
# We may or may not have a file for our rules
# We may or may not have iptables configured for our chains
# We sanity check all of these at the start of every action

def sanity_check
  # Check iptables FILTER table for our chef chain
  begin
    shell_out!('iptables -nL Promethean')
  rescue Mixlib::ShellOut::ShellCommandFailed
	info("Defining Promethean chain")
    shell_out!('iptables -N Promethean')
  end

  # Check iptables FILTER INPUT chain for a jump to our chef chain
  unless shell_out!('iptables -nL INPUT').stdout.lines.find { |line| line =~ /^Promethean[ ]*all/ }
	info("Adding Promethean chain to input table")
    shell_out!('iptables -A INPUT -j Promethean')
  end

  # Check the header of our file
  # If it's not there, blast the file and rewrite the header
  res = @new_resource
  saved_header = nil
  if ::File.exist?(res.script_path) and ::File.size(res.script_path) > 0
    saved_header = ::File.open(res.script_path) { |f| f.readline.chomp }
  end
  header = 'iptables -F Promethean'
  if saved_header.nil? || saved_header != header
    info("No header in #{res.script_path}, writing #{header}")
	::File.open(res.script_path, 'w') do |f|
      f.puts header
    end
    return true
  end

  false
end

def check_rule(action)
  # Quickly check our environment.
  # If we're dirty, we'll need to know later to reconfigure the kernel
  # with our file
  dirty = sanity_check
  # build our rule in a method
  rule = build_rule(action)

  # Look for our line in the script
  line = find_line(@new_resource.script_path, rule)

  # If we're removing, remove the line
  if action == 'remove'
    info('Not implemented yet')
    # if we find the line, we're considered dirty
    dirty = true
  end
  if line == 0
    # append our line to the end
    ::File.open(@new_resource.script_path, 'a') do |f|
      f.puts rule
    end
    dirty = true
  end

  if dirty
    execute "bash #{@new_resource.script_path}"
  end
  info("ran successfully")
end

def build_rule(action)
  rule = 'iptables -A Promethean '
  res = @new_resource

  rule += "-p #{res.protocol} "

  rule += "--dport #{res.port} "

  rule += "-s #{res.source} " unless res.source.nil?

  rule += "-d #{res.destination} " unless res.destination.nil?

  rule += "-i #{res.in_interface} " unless res.in_interface.nil?

  rule += "-j #{action} -m comment --comment \"Chef: "
  rule += "recipe[#{res.cookbook_name}::#{res.recipe_name}] #{res.name}\""
  rule
end

def find_line(file_name, needle)
  return 0 unless ::File.exists? file_name
  ::File.open(file_name) do |f|
    current_line = 1
    f.each_line do |line|
      return current_line if line.chomp == needle
      current_line += 1
    end
  end
  0
end

action :accept do
  check_rule('ACCEPT')
end
