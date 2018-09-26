zookeeper Cookbook
==================
TODO: Create zookeeper cluster node.

e.g.
This cookbook creates a clustered node for zookeeper.

Requirements
------------
TODO: Currently depends on promethean cookbook.

e.g.
#### packages
- `zookeeper` - zookeeper needs zookeeper RPM.

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
#### zookeeper::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['zookeeper']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### zookeeper::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `zookeeper` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[zookeeper]"
  ]
}
```

License and Authors
-------------------
Authors: TODO: Bryan Phinney <bryan.phinney@prometheanworld.com>
