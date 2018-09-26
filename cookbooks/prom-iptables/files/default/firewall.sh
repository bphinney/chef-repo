#!/bin/sh
iptables-restore /etc/firewall.conf
sh /etc/firewall.chef
