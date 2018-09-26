default['gluster']['gluster_version'] = '3.7.6-1'
# Default Environments to not create shared infrastructure for
default['gluster']["noenvirons"] = ["local", "_default", "tools", "zone-a", "zone-b", "zone-c", "localpoc", "loadtest2"]
# Default Environment for glusterfs servers
default["gluster_env"] = "tools"
# Default for EFS target
default['efs']['target'] = nil
