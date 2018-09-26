firewall LWRP
=============
This cookbook provides a LWRP that sets up iptables on a system.

Overview
--------
Currently, this cookbook is meant to be called from recipes in other cookbooks. It configures `/etc/firewall.chef` by default with a set of firewall rules provided by other cookbooks. These rules get put into a `chef` chain in the `FILTER` table. This provider also checks to make sure there is a `chef` chain in the `FILTER` table and is called from the `INPUT` chain.

Requirements
------------
- iptables
- Tested on ubuntu 12.04, but should work on all linux variants

Attributes
----------

#### firewall

| Key            | Type                    | Description                                                 | Default | Required |
|----------------|-------------------------|-------------------------------------------------------------|---------|----------|
| `port`         | Integer                 | The port number.                                            | None    | Yes      |
| `protocol`     | :tcp or :udp            | The protocol.                                               | :tcp    | No       |
| `source`       | CIDR                    | The IP range allowed.                                       | None    | No       |
| `destionation` | CIDR                    | The IP range allowed.                                       | None    | No       |
| `action`       | :accept, :drop, :remove | The target of the chain, or if the chain should be removed. | :accept | No       |

Usage
-----
Mark `firewall` as a depends in the metadata of the cookbook.

```ruby
name "cookbook"
depends "firewall", "~> 0.0"
```

Just include a call to the `firewall` resource in your recipe.

```ruby
firewall 'nginx' do
  port 80
end
```

```ruby
firewall 'mysql' do
  port 3306
  protocol :tcp
  source "10.0.0.0/24"
end
```

