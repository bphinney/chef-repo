# Many bits here stolen from https://github.com/opscode-cookbooks/firewall/blob/master/resources/rule.rb

IP_CIDR_VALID_REGEX = /\b(?:\d{1,3}\.){3}\d{1,3}\b(\/[0-3]?[0-9])?/

actions :accept, :reject, :remove

attribute :port, kind_of: Integer
attribute :protocol, kind_of: Symbol, equal_to: [:udp, :tcp]
attribute :script_path, kind_of: String
attribute :source, regex: IP_CIDR_VALID_REGEX
attribute :destination, regex: IP_CIDR_VALID_REGEX
attribute :in_interface, kind_of: String

def initialize(name, run_context = nil)
  super
  @action = :accept
  @script_path = '/etc/firewall.chef' if @script_path.nil?
  @protocol = :tcp
end
