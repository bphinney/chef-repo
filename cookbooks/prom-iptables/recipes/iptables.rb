# Example usage: (Thanks Wil)
#  firewall 'mysql' do
#    port 3306
#    protocol :tcp
#    source "10.0.0.0/24"
#  end

prom_iptables 'ssh' do 
  port 22
end

prom_iptables 'https' do 
  port 443
end

prom_iptables 'http' do 
  port 80
end
