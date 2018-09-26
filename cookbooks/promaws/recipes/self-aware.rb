###################################################
#                                                 #
# Cookbook Name:: promaws                        #
# Recipe:: self-aware                             #
#                                                 #
# Copyright 2014, Promethean                      #
#                                                 #
# All rights reserved - Do Not Redistribute       #
###################################################
#
# For now we are only supporting AWS/EC, should we
# need to support others, we will add them.
#
def self_machine
  require 'net/http'
  require 'socket'

  aws_addr = "169.254.169.254"
  aws_port = 80

  t = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
  aws_saddr = Socket.pack_sockaddr_in(aws_port, aws_addr)
  connected = false

  begin
    t.connect_nonblock(aws_saddr)
  rescue Errno::EINPROGRESS
    r,w,e = IO::select(nil,[t],nil,2)
  if !w.nil?
    connected = true; puts "provider: aws"
    node.normal["provider"] = "aws"
  else
    connected = false; puts "provider: local"
    node.normal["provider"] = "local"
    begin
      t.connect_nonblock(aws_saddr)
    rescue Errno::EISCONN
      t.close
      connected = true; puts "provider: aws"
      node.normal["provider"] = "aws"
    rescue SystemCallError
  end
  end
  rescue SystemCallError
  end
end

unless node.chef_environment.include?("local")
  self_machine
end
