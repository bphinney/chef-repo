#! /usr/bin/python
#Copyright 2014 Jeremy Carroll
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.


import json
import urllib2
import socket
import collections
from distutils.version import StrictVersion


ES_CLUSTER           = "elasticsearch"
ES_HOST              = "localhost"
ES_PORT              = 9200

# ES indexes must be fully qualified. E.g. _all, index1, index2
# To do:  Handle glob syntax for index names.
ES_INDEX             = [ ]

ENABLE_INDEX_STATS   = False
ENABLE_NODE_STATS    = True
ENABLE_CLUSTER_STATS = False

VERBOSE_LOGGING      = False

Stat = collections.namedtuple('Stat', ('type', 'path'))

# Indices are cluster wide, metrics should be collected from only one server
# in the cluster or from an external probe server.
INDEX_STATS = {

    # === Elasticsearch 0.90.x and higher ===
    "v('{es_version}') >= v('0.90.0')": {

        ## PRIMARIES
        # DOCS
        "indices.{index_name}.primaries.docs.count" : Stat("counter", "indices.%s.primaries.docs.count"),
        "indices.{index_name}.primaries.docs.deleted" : Stat("counter", "indices.%s.primaries.docs.deleted"),
        # STORE
        "indices.{index_name}.primaries.store.size_in_bytes" : Stat("bytes", "indices.%s.primaries.store.size_in_bytes"),
        "indices.{index_name}.primaries.store.throttle_time_in_millis" : Stat("counter", "indices.%s.primaries.store.throttle_time_in_millis"),
        # INDEXING
        "indices.{index_name}.primaries.indexing.index_total" : Stat("counter", "indices.%s.primaries.indexing.index_total"),
        "indices.{index_name}.primaries.indexing.index_time_in_millis" : Stat("counter", "indices.%s.primaries.indexing.index_time_in_millis"),
        "indices.{index_name}.primaries.indexing.index_current" : Stat("gauge", "indices.%s.primaries.indexing.index_current"),
        "indices.{index_name}.primaries.indexing.delete_total" : Stat("counter", "indices.%s.primaries.indexing.delete_total"),
        "indices.{index_name}.primaries.indexing.delete_time_in_millis" : Stat("counter", "indices.%s.primaries.indexing.delete_time_in_millis"),
        "indices.{index_name}.primaries.indexing.delete_current" : Stat("gauge", "indices.%s.primaries.indexing.delete_current"),
        # GET
        "indices.{index_name}.primaries.get.time_in_millis" : Stat("counter", "indices.%s.primaries.get.time_in_millis"),
        "indices.{index_name}.primaries.get.exists_total" : Stat("counter", "indices.%s.primaries.get.exists_total"),
        "indices.{index_name}.primaries.get.exists_time_in_millis" : Stat("counter", "indices.%s.primaries.get.exists_time_in_millis"),
        "indices.{index_name}.primaries.get.missing_total" : Stat("counter", "indices.%s.primaries.get.missing_total"),
        "indices.{index_name}.primaries.get.missing_time_in_millis" : Stat("counter", "indices.%s.primaries.get.missing_time_in_millis"),
        "indices.{index_name}.primaries.get.current" : Stat("gauge", "indices.%s.primaries.get.current"),
        # SEARCH
        "indices.{index_name}.primaries.search.open_contexts" : Stat("gauge", "indices.%s.primaries.search.open_contexts"),
        "indices.{index_name}.primaries.search.query_total" : Stat("counter", "indices.%s.primaries.search.query_total"),
        "indices.{index_name}.primaries.search.query_time_in_millis" : Stat("counter", "indices.%s.primaries.search.query_time_in_millis"),
        "indices.{index_name}.primaries.search.query_current" : Stat("gauge", "indices.%s.primaries.search.query_current"),
        "indices.{index_name}.primaries.search.fetch_total" : Stat("counter", "indices.%s.primaries.search.fetch_total"),
        "indices.{index_name}.primaries.search.fetch_time_in_millis" : Stat("counter", "indices.%s.primaries.search.fetch_time_in_millis"),
        "indices.{index_name}.primaries.search.fetch_current" : Stat("gauge", "indices.%s.primaries.search.fetch_current"),

        ## TOTAL ##
        # DOCS
        "indices.{index_name}.total.docs.count" : Stat("gauge", "indices.%s.total.docs.count"),
        "indices.{index_name}.total.docs.deleted" : Stat("gauge", "indices.%s.total.docs.deleted"),
        # STORE
        "indices.{index_name}.total.store.size_in_bytes" : Stat("gauge", "indices.%s.total.store.size_in_bytes"),
        "indices.{index_name}.total.store.throttle_time_in_millis" : Stat("counter", "indices.%s.total.store.throttle_time_in_millis"),
        # INDEXING
        "indices.{index_name}.total.indexing.index_total" : Stat("counter", "indices.%s.total.indexing.index_total"),
        "indices.{index_name}.total.indexing.index_time_in_millis" : Stat("counter", "indices.%s.total.indexing.index_time_in_millis"),
        "indices.{index_name}.total.indexing.index_current" : Stat("gauge", "indices.%s.total.indexing.index_current"),
        "indices.{index_name}.total.indexing.delete_total" : Stat("counter", "indices.%s.total.indexing.delete_total"),
        "indices.{index_name}.total.indexing.delete_time_in_millis" : Stat("counter", "indices.%s.total.indexing.delete_time_in_millis"),
        "indices.{index_name}.total.indexing.delete_current" : Stat("gauge", "indices.%s.total.indexing.delete_current"),
        # GET
        "indices.{index_name}.total.get.total" : Stat("counter", "indices.%s.total.get.total"),
        "indices.{index_name}.total.get.time_in_millis" : Stat("counter", "indices.%s.total.get.time_in_millis"),
        "indices.{index_name}.total.get.exists_total" : Stat("counter", "indices.%s.total.get.exists_total"),
        "indices.{index_name}.total.get.exists_time_in_millis" : Stat("counter", "indices.%s.total.get.exists_time_in_millis"),
        "indices.{index_name}.total.get.missing_total" : Stat("counter", "indices.%s.total.get.missing_total"),
        "indices.{index_name}.total.get.missing_time_in_millis" : Stat("counter", "indices.%s.total.get.missing_time_in_millis"),
        "indices.{index_name}.total.get.current" : Stat("gauge", "indices.%s.total.get.current"),
        # SEARCH
        "indices.{index_name}.total.search.open_contexts" : Stat("gauge", "indices.%s.total.search.open_contexts"),
        "indices.{index_name}.total.search.query_total" : Stat("counter", "indices.%s.total.search.query_total"),
        "indices.{index_name}.total.search.query_time_in_millis" : Stat("counter", "indices.%s.total.search.query_time_in_millis"),
        "indices.{index_name}.total.search.query_current" : Stat("gauge", "indices.%s.total.search.query_current"),
        "indices.{index_name}.total.search.fetch_total" : Stat("counter", "indices.%s.total.search.fetch_total"),
    },
    # === Elasticsearch 1.0.0 and higher ===
    "v('{es_version}') >= v('1.0.0')": {
        # TRANSLOG
        "indices.{index_name}.primaries.translog.size_in_bytes" : Stat("bytes", "indices.%s.primaries.translog.size_in_bytes"),
        "indices.{index_name}.primaries.translog.operations" : Stat("counter", "indices.%s.primaries.translog.operations"),
        # SEGMENTS
        "indices.{index_name}.primaries.segments.memory_in_bytes" : Stat("bytes", "indices.%s.primaries.segments.memory_in_bytes"),
        "indices.{index_name}.primaries.segments.count" : Stat("counter", "indices.%s.primaries.segments.count"),
        # ID_CACHE
        "indices.{index_name}.primaries.id_cache.memory_size_in_bytes" : Stat("bytes", "indices.%s.primaries.id_cache.memory_size_in_bytes"),
        # FLUSH
        "indices.{index_name}.primaries.flush.total" : Stat("counter", "indices.%s.primaries.flush.total"),
        "indices.{index_name}.primaries.flush.total_time_in_millis" : Stat("counter", "indices.%s.primaries.flush.total_time_in_millis"),
        # WARMER
        "indices.{index_name}.primaries.warmer.total.primaries.warmer.total_time_in_millis" : Stat("counter", "indices.%s.primaries.warmer.total_time_in_millis"),
        "indices.{index_name}.primaries.warmer.total" : Stat("counter", "indices.%s.primaries.warmer.total"),
        "indices.{index_name}.primaries.warmer.current" : Stat("gauge", "indices.%s.primaries.warmer.current"),
        # FIELDDATA
        "indices.{index_name}.primaries.fielddata.memory_size_in_bytes" : Stat("bytes", "indices.%s.primaries.fielddata.memory_size_in_bytes"),
        "indices.{index_name}.primaries.fielddata.evictions" : Stat("counter", "indices.%s.primaries.fielddata.evictions"),
        # REFRESH
        "indices.{index_name}.primaries.refresh.total_time_in_millis" : Stat("counter", "indices.%s.primaries.refresh.total_time_in_millis"),
        "indices.{index_name}.primaries.refresh.total" : Stat("counter", "indices.%s.primaries.refresh.total"),
        # MERGES
        "indices.{index_name}.primaries.merges.total_docs" : Stat("counter", "indices.%s.primaries.merges.total_docs"),
        "indices.{index_name}.primaries.merges.total_size_in_bytes" : Stat("bytes", "indices.%s.primaries.merges.total_size_in_bytes"),
        "indices.{index_name}.primaries.merges.current" : Stat("gauge", "indices.%s.primaries.merges.current"),
        "indices.{index_name}.primaries.merges.total" : Stat("counter", "indices.%s.primaries.merges.total"),
        "indices.{index_name}.primaries.merges.current_docs" : Stat("gauge", "indices.%s.primaries.merges.current_docs"),
        "indices.{index_name}.primaries.merges.total_time_in_millis" : Stat("counter", "indices.%s.primaries.merges.total_time_in_millis"),
        "indices.{index_name}.primaries.merges.current_size_in_bytes" : Stat("bytes", "indices.%s.primaries.merges.current_size_in_bytes"),
        # COMPELTION
        "indices.{index_name}.primaries.completion.size_in_bytes" : Stat("bytes", "indices.%s.primaries.completion.size_in_bytes"),
        # PERCOLATE
        "indices.{index_name}.primaries.percolate.total" : Stat("counter", "indices.%s.primaries.percolate.total"),
        "indices.{index_name}.primaries.percolate.memory_size_in_bytes" : Stat("bytes", "indices.%s.primaries.percolate.memory_size_in_bytes"),
        "indices.{index_name}.primaries.percolate.queries" : Stat("counter", "indices.%s.primaries.percolate.queries"),
        "indices.{index_name}.primaries.percolate.time_in_millis" : Stat("counter", "indices.%s.primaries.percolate.time_in_millis"),
        "indices.{index_name}.primaries.percolate.current" : Stat("gauge", "indices.%s.primaries.percolate.current"),
        # FILTER_CACHE
        "indices.{index_name}.primaries.filter_cache.evictions" : Stat("counter", "indices.%s.primaries.filter_cache.evictions"),
        "indices.{index_name}.primaries.filter_cache.memory_size_in_bytes" : Stat("bytes", "indices.%s.primaries.filter_cache.memory_size_in_bytes"),
    },
    # === Elasticsearch 1.1.0 and higher ===
    "v('{es_version}') >= v('1.1.0')": {
        ## SUGGEST
        "indices.{index_name}.primaries.suggest.total" : Stat("counter", "indices.%s.primaries.suggest.total"),
        "indices.{index_name}.primaries.suggest.time_in_millis" : Stat("counter", "indices.%s.primaries.suggest.time_in_millis"),
        "indices.{index_name}.primaries.suggest.current" : Stat("gauge", "indices.%s.primaries.suggest.current"),
    },
    # === Elasticsearch 1.3.0 and higher ===
    "v('{es_version}') >= v('1.3.0')": {
        ## SEGMENTS
        "indices.{index_name}.primaries.segments.index_writer_memory_in_bytes" : Stat("bytes", "indices.%s.primaries.segments.index_writer_memory_in_bytes"),
        "indices.{index_name}.primaries.segments.version_map_memory_in_bytes" : Stat("bytes", "indices.%s.primaries.segments.version_map_memory_in_bytes"),
    }
}

NODE_STATS = {

    # === Elasticsearch 0.90.x and higher ===
    "v('{es_version}') >= v('0.90.0')": {

        ## DOCS
        'indices.docs.count': Stat("gauge", "nodes.%s.indices.docs.count"),
        'indices.docs.deleted': Stat("counter", "nodes.%s.indices.docs.deleted"),

        ## STORE
        'indices.store.size': Stat("bytes", "nodes.%s.indices.store.size_in_bytes"),
        'indices.store.throttle-time': Stat("counter", "nodes.%s.indices.store.throttle_time_in_millis"),

        ## INDEXING
        'indices.indexing.index-total': Stat("counter", "nodes.%s.indices.indexing.index_total"),
        'indices.indexing.index-time': Stat("counter", "nodes.%s.indices.indexing.index_time_in_millis"),
        'indices.indexing.delete-total': Stat("counter", "nodes.%s.indices.indexing.delete_total"),
        'indices.indexing.delete-time': Stat("counter", "nodes.%s.indices.indexing.delete_time_in_millis"),
        'indices.indexing.index-current': Stat("gauge", "nodes.%s.indices.indexing.index_current"),
        'indices.indexing.delete-current': Stat("gauge", "nodes.%s.indices.indexing.delete_current"),

        ## GET
        'indices.get.total': Stat("counter", "nodes.%s.indices.get.total"),
        'indices.get.time': Stat("counter", "nodes.%s.indices.get.time_in_millis"),
        'indices.get.exists-total': Stat("counter", "nodes.%s.indices.get.exists_total"),
        'indices.get.exists-time': Stat("counter", "nodes.%s.indices.get.exists_time_in_millis"),
        'indices.get.missing-total': Stat("counter", "nodes.%s.indices.get.missing_total"),
        'indices.get.missing-time': Stat("counter", "nodes.%s.indices.get.missing_time_in_millis"),
        'indices.get.current': Stat("gauge", "nodes.%s.indices.get.current"),

        ## SEARCH
        'indices.search.query-current': Stat("gauge", "nodes.%s.indices.search.query_current"),
        'indices.search.query-total': Stat("counter", "nodes.%s.indices.search.query_total"),
        'indices.search.query-time': Stat("counter", "nodes.%s.indices.search.query_time_in_millis"),
        'indices.search.fetch-current': Stat("gauge", "nodes.%s.indices.search.fetch_current"),
        'indices.search.fetch-total': Stat("counter", "nodes.%s.indices.search.fetch_total"),
        'indices.search.fetch-time': Stat("counter", "nodes.%s.indices.search.fetch_time_in_millis"),
        'indices.search.open-contexts': Stat("gauge", "nodes.%s.indices.search.open_contexts"),

        ## CACHE
        'indices.cache.field.eviction': Stat("counter", "nodes.%s.indices.fielddata.evictions"),
        'indices.cache.field.size': Stat("bytes", "nodes.%s.indices.fielddata.memory_size_in_bytes"),
        'indices.cache.filter.evictions': Stat("counter", "nodes.%s.indices.filter_cache.evictions"),
        'indices.cache.filter.size': Stat("bytes", "nodes.%s.indices.filter_cache.memory_size_in_bytes"),


        # JVM METRICS #
        ##GC
        'jvm.gc.time': Stat("counter", "nodes.%s.jvm.gc.collectors.young.collection_time_in_millis"),
        'jvm.gc.count': Stat("counter", "nodes.%s.jvm.gc.collectors.young.collection_count"),
        'jvm.gc.old-time': Stat("counter", "nodes.%s.jvm.gc.collectors.old.collection_time_in_millis"),
        'jvm.gc.old-count': Stat("counter", "nodes.%s.jvm.gc.collectors.old.collection_count"),
        'jvm.gc.young-count': Stat("counter", "nodes.%s.jvm.gc.collectors.young.collection_count"),
        'jvm.gc.young-time': Stat("counter", "nodes.%s.jvm.gc.collectors.young.collection_time_in_millis"),

        ## MEM
        'jvm.mem.heap-committed': Stat("bytes", "nodes.%s.jvm.mem.heap_committed_in_bytes"),
        'jvm.mem.heap-used': Stat("bytes", "nodes.%s.jvm.mem.heap_used_in_bytes"),
        'jvm.mem.heap-used-percent': Stat("percent", "nodes.%s.jvm.mem.heap_used_percent"),
        'jvm.mem.non-heap-committed': Stat("bytes", "nodes.%s.jvm.mem.non_heap_committed_in_bytes"),
        'jvm.mem.non-heap-used': Stat("bytes", "nodes.%s.jvm.mem.non_heap_used_in_bytes"),

        ## POOLS
        'jvm.pools.young-used': Stat("counter", "nodes.%s.jvm.mem.pools.young.used_in_bytes"),
        'jvm.pools.young-max': Stat("counter", "nodes.%s.jvm.mem.pools.young.max_in_bytes"),
        'jvm.pools.survivor-used': Stat("counter", "nodes.%s.jvm.mem.pools.survivor.used_in_bytes"),
        'jvm.pools.survivor-max': Stat("counter", "nodes.%s.jvm.mem.pools.survivor.max_in_bytes"),
        'jvm.pools.old-used': Stat("counter", "nodes.%s.jvm.mem.pools.old.used_in_bytes"),
        'jvm.pools.old-max': Stat("counter", "nodes.%s.jvm.mem.pools.old.max_in_bytes"),

        ## THREADS
        'jvm.threads.count': Stat("counter", "nodes.%s.jvm.threads.count"),
        'jvm.threads.peak_count': Stat("counter", "nodes.%s.jvm.threads.peak_count"),

        # TRANSPORT METRICS #
        'transport.server_open': Stat("gauge", "nodes.%s.transport.server_open"),
        'transport.rx.count': Stat("counter", "nodes.%s.transport.rx_count"),
        'transport.rx.size': Stat("bytes", "nodes.%s.transport.rx_size_in_bytes"),
        'transport.tx.count': Stat("counter", "nodes.%s.transport.tx_count"),
        'transport.tx.size': Stat("bytes", "nodes.%s.transport.tx_size_in_bytes"),

        # HTTP METRICS #
        'http.current_open': Stat("gauge", "nodes.%s.http.current_open"),
        'http.total_open': Stat("counter", "nodes.%s.http.total_opened"),

        # PROCESS METRICS #
        'process.open_file_descriptors': Stat("gauge", "nodes.%s.process.open_file_descriptors"),
    },

    # === Elasticsearch 0.90.x only ===
    "v('0.90.0') <= v('{es_version}') < v('1.0.0')": {
        ##CPU
        'process.cpu.percent': Stat("gauge", "nodes.%s.process.cpu.percent")
    },

    # === Elasticsearch 1.0.0 or greater ===
    "v('{es_version}') >= v('1.0.0')": {
        ## STORE
        'indices.store.throttle-time': Stat("counter", "nodes.%s.indices.store.throttle_time_in_millis"),

        ##SEARCH
        'indices.search.open-contexts': Stat("gauge", "nodes.%s.indices.search.open_contexts"),

        ##CACHE
        'indices.cache.field.eviction': Stat("counter", "nodes.%s.indices.fielddata.evictions"),
        'indices.cache.field.size': Stat("bytes", "nodes.%s.indices.fielddata.memory_size_in_bytes"),
        'indices.cache.filter.evictions': Stat("counter", "nodes.%s.indices.filter_cache.evictions"),
        'indices.cache.filter.size': Stat("bytes", "nodes.%s.indices.filter_cache.memory_size_in_bytes"),

        ## FLUSH
        'indices.flush.total': Stat("counter", "nodes.%s.indices.flush.total"),
        'indices.flush.time': Stat("counter", "nodes.%s.indices.flush.total_time_in_millis"),

        ## MERGES
        'indices.merges.current': Stat("gauge", "nodes.%s.indices.merges.current"),
        'indices.merges.current-docs': Stat("gauge", "nodes.%s.indices.merges.current_docs"),
        'indices.merges.current-size': Stat("bytes", "nodes.%s.indices.merges.current_size_in_bytes"),
        'indices.merges.total': Stat("counter", "nodes.%s.indices.merges.total"),
        'indices.merges.total-docs': Stat("gauge", "nodes.%s.indices.merges.total_docs"),
        'indices.merges.total-size': Stat("bytes", "nodes.%s.indices.merges.total_size_in_bytes"),
        'indices.merges.time': Stat("counter", "nodes.%s.indices.merges.total_time_in_millis"),

        ## REFRESH
        'indices.refresh.total': Stat("counter", "nodes.%s.indices.refresh.total"),
        'indices.refresh.time': Stat("counter", "nodes.%s.indices.refresh.total_time_in_millis"),

        ## SEGMENTS
        'indices.segments.count': Stat("gauge", "nodes.%s.indices.segments.count"),
        'indices.segments.size': Stat("bytes", "nodes.%s.indices.segments.memory_in_bytes"),

        ## TRANSLOG
        'indices.translog.operations': Stat("gauge", "nodes.%s.indices.translog.operations"),
        'indices.translog.size': Stat("bytes", "nodes.%s.indices.translog.size_in_bytes"),
    },

    # DICT: Elasticsearch 1.3.0 or greater
    "v('{es_version}') >= v('1.3.0')": {
        'indices.segments.index-writer-memory': Stat("bytes", "nodes.%s.indices.segments.index_writer_memory_in_bytes"),
        'indices.segments.index-memory': Stat("bytes", "nodes.%s.indices.segments.memory_in_bytes"),
    }
}

CLUSTER_STATS = {
    # === Elasticsearch 0.90.x and higher ===
    "v('{es_version}') >= v('0.90.0')": {
        'active_primary_shards': Stat("gauge", "cluster.%s.active_primary_shards"),
        'active_shards': Stat("gauge", "cluster.%s.active_shards"),
        'initializing_shards': Stat("gauge", "cluster.%s.initializing_shards"),
        'number_of_data_nodes': Stat("gauge", "cluster.%s.number_of_data_nodes"),
        'number_of_nodes': Stat("gauge", "cluster.%s.number_of_nodes"),
        'relocating_shards': Stat("gauge", "cluster.%s.relocating_shards"),
        'unassigned_shards': Stat("gauge", "cluster.%s.unassigned_shards"),
    }
}


def check_es_version(rule, version):
    log_verbose('Elasticsearch version rule: %s' % (rule.format(es_version=version)) )
    v = StrictVersion
    eval_string = rule.format(es_version=version)
    return eval(eval_string)


def generate_metric_set(rules, es_version):
    """
    @brief - Iterate over the first level keys in the "rules" dictionary
    and evaluate the key as a Python statement.  When a key evaluates as true,
    the value is merged into a dictionary containing the sythesised metrics.

    @rules - a dictionary containing keys which define a rule to be evaluated
    with the elasticsearch version number.  The rule must be valid python and
    return a True/False result.

    @es_version - A string containing the Elasticsearch version which must be
    compatiable with distutils.version's VersionStrict function.

    @returns - A dictionary containing the metrics to be fetched that are available
    for the Elasticsearch version.
    """
    synthesised_metrics = {}

    for k in rules.keys():
        if check_es_version(k, es_version):
            log_verbose("Adding metrics for rule : %s" % k)
            synthesised_metrics.update(rules[k])

    return synthesised_metrics



def lookup_stat(stat, json):
    """
    Collect stats from JSON result
    """
    log_verbose("lookup_node_stat: node=%s " % stat)
    val = dig_it_up(json, stat)

    # Check to make sure we have a valid result
    # dig_it_up returns False if no match found
    if not isinstance(val, bool):
        return int(val)
    else:
        return None


def lookup_index_stat(stat, metrics, json):
    indices = json['indices'].keys()

    for index in indices:
        formatted_stat = stat.format(index_name=index)
        val = index_dig_it_up(json, metrics[stat].path, index )

    # Check to make sure we have a valid result
    # dig_it_up returns False if no match found
    if not isinstance(val, bool):
        return int(val)
    else:
        return None


def log_verbose(msg):
    if VERBOSE_LOGGING == True:
        collectd.warning('elasticsearch plugin [verbose]: %s' % msg)


def configure_callback(conf):
    """Received configuration information"""
    global ES_HOST, ES_PORT, VERBOSE_LOGGING, ES_CLUSTER, ES_INDEX, ENABLE_INDEX_STATS, ENABLE_NODE_STATS, ENABLE_CLUSTER_STATS
    for node in conf.children:
        if node.key == 'Host':
            ES_HOST = node.values[0]
        elif node.key == 'Port':
            ES_PORT = int(node.values[0])
        elif node.key == 'Verbose':
            VERBOSE_LOGGING = bool(node.values[0])
        elif node.key == 'Cluster':
            ES_CLUSTER = node.values[0]
        elif node.key == 'Indexes':
            ES_INDEX = node.values
            log_verbose('Indexes to query: %s' % (str(ES_INDEX)))
        elif node.key == 'EnableIndexStats':
            ENABLE_INDEX_STATS = bool(node.values[0])
            log_verbose("Enable Index Stats : %s" % ENABLE_INDEX_STATS)
        elif node.key == 'EnableNodeStats':
            ENABLE_NODE_STATS = bool(node.values[0])
            log_verbose("Enable Node Stats : %s" % ENABLE_NODE_STATS)
        elif node.key == 'EnableClusterHealth':
            ENABLE_CLUSTER_STATS = bool(node.values[0])
            log_verbose("Enable Cluster Health : %s" % ENABLE_CLUSTER_STATS)
        else:
            collectd.warning('elasticsearch plugin: Ignoring unknown config key: %s.' % node.key)

    log_verbose('Configured with host=%s, port=%s' % (ES_HOST, ES_PORT))



def fetch_url(url):
    try:
        result = json.load(urllib2.urlopen(url, timeout=10))
    except urllib2.URLError, e:
        collectd.error('elasticsearch plugin: Error connecting to %s - %r' % (url, e))
        return None
    return result



def fetch_stats():
    global ES_CLUSTER, ES_HOST, ES_PORT, ES_INDEX, ENABLE_NODE_STATS, ENABLE_INDEX_STATS, ENABLE_CLUSTER_STATS

    NODE_STATS_URL = {
        "v('0.90.0') <= v('{es_version}') < v('1.0.0')": '{url}_cluster/nodes/_local/stats?http=true&process=true&jvm=true&transport=true&thread_pool=true',
        "v('{es_version}') >= v('1.0.0')" : '{url}_nodes/_local/stats/transport,http,process,jvm,indices,thread_pool'
    }

    node_stats_url = ""
    base_url = 'http://' + ES_HOST + ':' + str(ES_PORT) + '/'
    server_info = fetch_url(base_url)
    version = server_info['version']['number']

    # Get the cluster name.
    if server_info.has_key("cluster_name"):
        ES_CLUSTER = server_info["cluster_name"]
    else:
        ES_CLUSTER = fetch_url(base_url+"_nodes")['cluster_name']

    log_verbose('Elasticsearch cluster: %s version : %s' % (ES_CLUSTER, version))

    # Node statistics
    if ENABLE_NODE_STATS:
        node_metrics = {}
        for url_version_rule in NODE_STATS_URL.keys():
            if check_es_version(url_version_rule, str(version)):
                node_stats_url = NODE_STATS_URL[url_version_rule].format(url=base_url)
                log_verbose('Node url : %s' % node_stats_url)
                # Stop when the first rule is evaluated as true.
                break

        node_metrics.update(generate_metric_set(NODE_STATS, version))

        # add info on thread pools
        for pool in ['generic', 'index', 'get', 'snapshot', 'merge', 'optimize', 'bulk', 'warmer', 'flush', 'search', 'refresh']:
            for attr in ['threads', 'queue', 'active', 'largest']:
                path = 'thread_pool.{0}.{1}'.format(pool, attr)
                node_metrics[path] = Stat("gauge", 'nodes.%s.{0}'.format(path))
            for attr in ['completed', 'rejected']:
                path = 'thread_pool.{0}.{1}'.format(pool, attr)
                node_metrics[path] = Stat("counter", 'nodes.%s.{0}'.format(path))

        node_stats = fetch_url(node_stats_url)
        parse_node_stats(node_metrics, node_stats)

    # Indexes statistics
    if ENABLE_INDEX_STATS:
        index_metrics = {}

        for k in ES_INDEX:
            index_stats_url = base_url + k + "/_stats"
            index_metrics.update(generate_metric_set(INDEX_STATS, version))

            index_json = fetch_url(index_stats_url)
            parse_index_stats(index_metrics, index_json, k)

    # Cluster Stats
    if ENABLE_CLUSTER_STATS:
        cluster_metrics = {}
        cluster_metrics.update(generate_metric_set(CLUSTER_STATS, version))

        cluster_health = fetch_url(base_url+"_cluster/health")
        parse_cluster_stats(cluster_metrics, cluster_health)

    return True



def parse_node_stats(metrics, json):
    """Parse stats response from Elasticsearch"""
    node = json['nodes'].keys()[0]
    for name, key in metrics.iteritems():
        result = lookup_stat( metrics[name].path % node, json)
        dispatch_stat(result, name, key)
    return True


def parse_index_stats(metrics, json, index):
    """Parse stats response from Elasticsearch"""
    for name, key in metrics.iteritems():
        result = lookup_index_stat(name, metrics, json)
        dispatch_stat(result, name.format(index_name=index), key)
    return True


def parse_cluster_stats(metrics, stats):
    """Parse stats response from Elasticsearch"""
    global ES_CLUSTER
    for name, key in metrics.iteritems():
        result = lookup_stat(name, stats)
        # FIXME: This works but is messy.
        dispatch_stat(result, str(key.path) % ES_CLUSTER, key )
    return True


def dispatch_stat(result, name, key):
    """Read a key from info response data and dispatch a value"""
    if result is None:
        collectd.warning('elasticsearch plugin: Value not found for %s' % name)
        return
    estype = key.type
    value = int(result)
    log_verbose('Sending value[%s]: %s=%s' % (estype, name, value))

    val = collectd.Values(plugin='elasticsearch')
    val.plugin_instance = ES_CLUSTER
    val.type = estype
    val.type_instance = name
    val.values = [value]
    val.meta={'0': True}
    val.dispatch()


def read_callback():
    log_verbose('Read callback called')
    stats = fetch_stats()



def dig_it_up(obj, path):
    try:
        if type(path) in (str, unicode):
            path = path.split('.')
            return reduce(lambda x, y: x[y], path, obj)
    except:
        return False


def index_dig_it_up(obj, path, index_name):
    try:
        if type(path) in (str, unicode):
            path = path.split('.')
            path[1] = path[1] % index_name
            return reduce(lambda x, y: x[y], path, obj)
    except:
        return False

# The following classes are there to launch the plugin manually
# with something like ./elasticsearch_collectd.py for development
# purposes. They basically mock the calls on the "collectd" symbol
# so everything prints to stdout.
class CollectdMock(object):
    def __init__(self, print_mode="debug"):
        if print_mode == "debug":
            self.value_mock = CollectdValuesDebugMock
        elif print_mode == "graphite":
            self.value_mock = CollectdValuesGraphiteMock
        else:
            raise NotImplementedError


    def error(self, msg):
        print 'ERROR: {}'.format(msg)
        sys.exit(1)

    def Values(self, plugin='elasticsearch'):
        return (self.value_mock)()

class CollectdValuesMock(object):
    def dispatch(self):
        raise NotImplementedError

    def __str__(self):
        attrs = []
        for name in dir(self):
            if not name.startswith('_') and name is not 'dispatch':
                attrs.append("{}={}".format(name, getattr(self, name)))
        return "<CollectdValues {}>".format(' '.join(attrs))

class CollectdValuesDebugMock(CollectdValuesMock):
    def dispatch(self):
        print self

class CollectdValuesGraphiteMock(CollectdValuesMock):
    def dispatch(self):
        inverse_hostname = '.'.join(
            reversed(
                socket.gethostname().split(".")
            )
        )
        print "{}.elasticsearch-{}.{}-{} {} {}".format(
            inverse_hostname,
            self.plugin_instance,
            self.type,
            self.type_instance,
            self.values[0],
            datetime.datetime.now().strftime("%s")
        )

if __name__ == '__main__':
    import argparse
    import datetime
    import socket
    import sys
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", type=str, default="debug")
    args = parser.parse_args()
    collectd = CollectdMock(print_mode=args.mode)
    fetch_stats()
else:
    import collectd
    collectd.register_config(configure_callback)
    collectd.register_read(read_callback)
