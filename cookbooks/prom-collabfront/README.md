<<<<<<< 60a29907d86a5484993ab144c18b927b347f49fe
prom-collabfront Cookbook
=========================
=======
prom-collabserver Cookbook
==========================
>>>>>>> New cookbook
TODO: Enter the cookbook description here.

e.g.
This cookbook makes your favorite breakfast sandwich.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### packages
<<<<<<< 60a29907d86a5484993ab144c18b927b347f49fe
- `toaster` - prom-collabfront needs toaster to brown your bagel.
=======
- `toaster` - prom-collabserver needs toaster to brown your bagel.
>>>>>>> New cookbook

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
<<<<<<< 60a29907d86a5484993ab144c18b927b347f49fe
#### prom-collabfront::default
=======
#### prom-collabserver::default
>>>>>>> New cookbook
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
<<<<<<< 60a29907d86a5484993ab144c18b927b347f49fe
    <td><tt>['prom-collabfront']['bacon']</tt></td>
=======
    <td><tt>['prom-collabserver']['bacon']</tt></td>
>>>>>>> New cookbook
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
<<<<<<< 60a29907d86a5484993ab144c18b927b347f49fe
#### prom-collabfront::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `prom-collabfront` in your node's `run_list`:
=======
#### prom-collabserver::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `prom-collabserver` in your node's `run_list`:
>>>>>>> New cookbook

```json
{
  "name":"my_node",
  "run_list": [
<<<<<<< 60a29907d86a5484993ab144c18b927b347f49fe
    "recipe[prom-collabfront]"
=======
    "recipe[prom-collabserver]"
>>>>>>> New cookbook
  ]
}
```

Contributing
------------
TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: TODO: List authors
