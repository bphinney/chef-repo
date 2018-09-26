user_management Cookbook
========================
This is an extension of the users cookbook to maintain users for Promethean.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### packages
- `users` - user_management needs users cookbook to provide LWRP for user management.

Data Bags
----------
#### data bag item users username
<table>
  <tr>
    <th>{  </th>
    <th>  "id": "username",  </th>
    <th>  "ssh_keys": "ssh-rsa AAAAB.....T2yo0F username",  </th>
    <th>  "groups": [ </th>
    <th>  "bphinney", </th>
    <th>  "sysadmin", "javadev"  </th>
    <th>  ], </th>
    <th>  "uid": 2499,</th>
    <th>  "comment": "User Name - username@prometheanworld.com"</th>
    <th>}</th>
  </tr>
</table>

Usage
-----
#### user_management::default

Just include `user_management::groupname` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[user_management::javadev]"
  ]
}
```

Contributing
------------

License and Authors
-------------------
Authors: 
bryan.phinney@prometheanworld.com
