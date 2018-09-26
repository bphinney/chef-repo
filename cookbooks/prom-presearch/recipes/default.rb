#
# Cookbook Name:: prom-presearch
# Recipe:: default
#
# Copyright 2015, Promethean
#
# All rights reserved - Do Not Redistribute
#
# Precached and centralized attribute search

######################
# Node Search/Filter #
######################

$all_nodes = search(:node)

$presearch_node = {

  # dotcms nodes - all environments
  'dotcms_role_nodes'   => $all_nodes.select { |n| n.role?('dotcms') },

  # prworld nodes - all environments
  'prworld_role_nodes'   => $all_nodes.select { |n| n.role?('prworld') },

  # dotcms nodes - per environment
  'dotcms_nodes'   => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                .select { |n| n.role?('dotcms') },

  # prworld nodes - per environment
  'prworld_nodes'   => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                 .select { |n| n.role?('prworld') },

  # classflow frontend nodes
  'frontend_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                .select { |n| n.role?('frontend') },

  # backendmajor nodes
  'backendmajor_nodes' => $all_nodes.select { |n| n.chef_environment == "dev2" }
                                .select { |n| n.recipe?('prom-activfoundation::activfoundation') },

  # backendminor nodes
  'backendminor_nodes' => $all_nodes.select { |n| n.chef_environment == "dev" }
                                .select { |n| n.recipe?('prom-activfoundation::activfoundation') },

  # frontendmajor nodes
  'frontendmajor_nodes' => $all_nodes.select { |n| n.chef_environment == "dev2" }
                                .select { |n| n.recipe?('prom-classfront::classflow') },

  # frontendminor nodes
  'frontendminor_nodes' => $all_nodes.select { |n| n.chef_environment == "dev" }
                                .select { |n| n.recipe?('prom-classfront::classflow') },

  # authserver nodes - per environment
  'authserver_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                  .select { |n| n.recipe?('prom-authserver::default') },

  # parentservice nodes - per environment
  'parentservice_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                  .select { |n| n.recipe?('prom-parentservice::default') },

  # storeservice nodes - per environment
  'storeservice_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                  .select { |n| n.recipe?('prom-storeservice::default') },
  # primary metrics host
  'metrics_host'   => $all_nodes.select { |n| n['stagemonitorrole'] == 'primary' }
                                .select { |n| n.recipe?('prom-metrics::stagemonitor') },

  # NFS servers marked as primary
  'nfs_primaries'    => $all_nodes.select { |n| n['nfs-server'] == 'primary' },

  # All NFS Servers
  'nfs_servers'      => $all_nodes.select { |n| n.role?('glusterfs') }
                                  .select { |n| n.chef_environment == "tools" },
  # NFS Servers in gluster_env
  'gluster_servers'  => $all_nodes.select { |n| n.role?('glusterfs') }
                                  .select { |n| n.chef_environment == "#{node['gluster_env']}" },

  # All NFS everywhere
  'all_nfsservers'   => $all_nodes.select { |n| n.role?('glusterfs') },

  # Gluster Servers - per environment
  'gluster_nodes'  => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                .select { |n| n.role?('glusterfs') },
  
  # Gluster Primary Servers - per environment
  'gluster_primary' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                 .select { |n| n['nfs-server'] == 'primary' },

  # activfoundation nodes
  'activfoundation_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                       .select { |n| n.role?('backend') },

  # aftraffic nodes
  'aftraffic_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                 .select { |n| n[:tags] == "*foundationtraffic*" }
                                 .select { |n| n.role?('backend') },

  ## collabserver nodes
  #'collabserver_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
  #                                  .select { |n| n.role?('collabserver') }, 

  # collabserver nodes
  'collabserver_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                    .select { |n| n.role?('collabserver') },

  # afmanager nodes
  'afmanager_nodes' => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                 .select { |n| n.role?('founmanagement') },

  # Elasticsearch nodes 
  'elasticsearch_nodes'   => $all_nodes.select { |n| n.chef_environment == "tools" }
                                       .select { |n| n.role?(node['af']['elasticrole']) },
  # Rabbitmq nodes
  'rabbitmq_nodes'    => $all_nodes.select { |n| n.role?('rabbitmq') },

  # Zookeeper nodes
  #'zookeeper_nodes'    => $all_nodes.select { |n| n.recipe?('zookeeper') },

  # Loadtest2 Zookeeper Nodes
  'zookeeper_nodes'    => $all_nodes.select { |n| n.chef_environment == node["zookeeper_env"]}
                                    .select { |n| n.role?('zookeeper') },
  # Zookeeper cluster
  'zookeeper_cluster'    => $all_nodes.select { |n| n.chef_environment == node.chef_environment }
                                      .select { |n| n.role?('zookeeper') },

  # Nagios Server
  'nagios_nodes'     => $all_nodes.select { |n| n.role?('monitoring') },

  # Yumrepo Server
  'yumrepo_nodes'    => $all_nodes.select { |n| n.role?('yumrepo') },

}

##########################
# Conditional Statements #
##########################
# Rabbitmq Cluster
unless node['aws'].is_a?(Hash) && "#{node['aws']['av_zone']}" != ""
 node.set['aws']['av_zone'] = `curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
end

$presearch_node['rabbitmq_cluster']    = $all_nodes.select { |n| 
    n['aws'].is_a?(Hash) && n['aws']['av_zone'] == node['aws']['av_zone'] }
                                     .select { |n| n.role?('rabbitmq') }
# DataCenter Nodes
$presearch_node['datacenter_nodes']   = $all_nodes.select { |n|
    n['aws'].is_a?(Hash) && n['aws']['region'] == node['aws']['region'] }
                                     .select { |n| n['provider'] == "aws" }
#############################
# Environ
#############################

$presearch_envs = search(:environment, "name:*",
    :filter_result  => {
        # Environment name for iteration and search
        'envname'        => ['name'],
        'dbservername'   => ['default_attributes','database','dbservername'],
        'dotcmsdbname'   => ['default_attributes','dotcms','dotcmsdbname'],
        'dotcmsdbuser'   => ['default_attributes','dotcms','dotcmsdbuser'],
        'dotcmsdbpass'   => ['default_attributes','dotcms','dotcmsdbpass'],
        'prworlddbname'  => ['default_attributes','prworld','prworlddbname'],
        'prworlddbuser'  => ['default_attributes','prworld','prworlddbuser'],
        'prworlddbpass'  => ['default_attributes','prworld','prworlddbpass'],
        })
