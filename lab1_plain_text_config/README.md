# Lab1: First envoy configuration

In this lab you will run an _[Envoy](https://www.envoyproxy.io/)_ with a static configuration to proxy to the _[Nginx](https://www.nginx.com/)_ web servers located in each Virtual Machine.

# Lab Goal

In this lab you'll practice how to run an _[Envoy](https://www.envoyproxy.io/)_ instance loading a boostrap configuration file.
You'll take a look into the configuration file to understand a bit more of the important chunks of configuration and how they affect _[Envoy](https://www.envoyproxy.io/)_ behaviour.

# Checking needed components

If you used the default settings of the _Vagrantfile_ you'll may check that all the _[Nginx](https://www.nginx.com/)_ web servers are running. To do so, please execute the same commands you see below:

```bash
ζ vagrant ssh node-3
Last login: Fri Apr 10 11:56:24 2020 from 10.0.2.2
[vagrant@localhost ~]$ curl http://172.28.128.3
Hello from node 3
[vagrant@localhost ~]$ curl http://172.28.128.4
Hello from node 4
[vagrant@localhost ~]$ curl http://172.28.128.5
Hello from node 5
[vagrant@localhost ~]$ 
```

# Envoy configuration

To run _[Envoy](https://www.envoyproxy.io/)_ as a proxy between all the running instances you may use the configuration file *envoy_config.yaml*. This file is located in the [~/home/vagrant/configuration_for_labs/lab1_plain_text_config/envoy_config.yaml](./lab1_plain_text_config/envoy_config.yaml).
This file contains a basic configuration you will need to adjust for each node. You will only need to adjust it if you want to boot envoy in all nodes, otherwise you may leave this configuration file as it is if you run _[Envoy](https://www.envoyproxy.io/)_ only in _node-3_.

If you want to run _[Envoy](https://www.envoyproxy.io/)_  in all nodes, then you may change the following values in the configuration file:

* IP address of the node.
* Name of the node.

_[Envoy](https://www.envoyproxy.io/)_ uses two directives to wake up _listeners_ and connect to different _upstreams_. In the configuration file take a look to the following definitions:

* _listeners_: here you will define which listeners you want _[Envoy](https://www.envoyproxy.io/)_ to open. In this example it will open port 10000 to listen to any request. This requests will be processed by the _filters_ defined in the _filter chain_. In this example they will proxy the traffic to a _cluster_ named *service_nginx*.
* _clusters_: her you will find a definition of a _cluster_. In this example is configured a an _STATIC_ cluster with a hardcoded list of _endpoints_. These _endpoints_ are the _[Nginx](https://www.nginx.com/)_ web servers of each node set in this lab.

## Load balancing

The provided configuration in this example will balance the traffic based on the *load_balancing_weight* directive. If you take a look to the configuration file you'll see that the weights are distributed asymmetrically. _node-3_ has 10% of traffic, _node-4_ 20% and _node-5_ 70%.

# Running Envoy

Now that the lab is set up, you may run _[Envoy](https://www.envoyproxy.io/)_.

First you will need to _SSH_ into one node and then use the provided configuration file to run _[Envoy](https://www.envoyproxy.io/)_.

```bash
ζ vagrant ssh node-3
Last login: Fri Apr 10 16:16:13 2020 from 10.0.2.2
[vagrant@localhost ~]$ ls
configuration_for_labs

[vagrant@localhost ~]$ cd configuration_for_labs/lab1_plain_text_config/

[vagrant@localhost lab1_plain_text_config]$ ls
README.md  envoy_config.yaml

[vagrant@localhost lab1_plain_text_config]$ envoy -c envoy_config.yaml 
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:255] initializing epoch 0 (hot restart version=11.104)
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:257] statically linked extensions:
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.clusters: envoy.cluster.eds, envoy.cluster.logical_dns, envoy.cluster.original_dst, envoy.cluster.static, envoy.cluster.strict_dns, envoy.clusters.aggregate, envoy.clusters.dynamic_forward_proxy, envoy.clusters.redis
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.tracers: envoy.dynamic.ot, envoy.lightstep, envoy.tracers.datadog, envoy.tracers.dynamic_ot, envoy.tracers.lightstep, envoy.tracers.opencensus, envoy.tracers.xray, envoy.tracers.zipkin, envoy.zipkin
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.filters.network: envoy.client_ssl_auth, envoy.echo, envoy.ext_authz, envoy.filters.network.client_ssl_auth, envoy.filters.network.direct_response, envoy.filters.network.dubbo_proxy, envoy.filters.network.echo, envoy.filters.network.ext_authz, envoy.filters.network.http_connection_manager, envoy.filters.network.kafka_broker, envoy.filters.network.local_ratelimit, envoy.filters.network.mongo_proxy, envoy.filters.network.mysql_proxy, envoy.filters.network.ratelimit, envoy.filters.network.rbac, envoy.filters.network.redis_proxy, envoy.filters.network.sni_cluster, envoy.filters.network.tcp_proxy, envoy.filters.network.thrift_proxy, envoy.filters.network.zookeeper_proxy, envoy.http_connection_manager, envoy.mongo_proxy, envoy.ratelimit, envoy.redis_proxy, envoy.tcp_proxy
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.resolvers: envoy.ip
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.filters.http: envoy.buffer, envoy.cors, envoy.csrf, envoy.ext_authz, envoy.fault, envoy.filters.http.adaptive_concurrency, envoy.filters.http.aws_lambda, envoy.filters.http.aws_request_signing, envoy.filters.http.buffer, envoy.filters.http.cache, envoy.filters.http.cors, envoy.filters.http.csrf, envoy.filters.http.dynamic_forward_proxy, envoy.filters.http.dynamo, envoy.filters.http.ext_authz, envoy.filters.http.fault, envoy.filters.http.grpc_http1_bridge, envoy.filters.http.grpc_http1_reverse_bridge, envoy.filters.http.grpc_json_transcoder, envoy.filters.http.grpc_stats, envoy.filters.http.grpc_web, envoy.filters.http.gzip, envoy.filters.http.header_to_metadata, envoy.filters.http.health_check, envoy.filters.http.ip_tagging, envoy.filters.http.jwt_authn, envoy.filters.http.lua, envoy.filters.http.on_demand, envoy.filters.http.original_src, envoy.filters.http.ratelimit, envoy.filters.http.rbac, envoy.filters.http.router, envoy.filters.http.squash, envoy.filters.http.tap, envoy.grpc_http1_bridge, envoy.grpc_json_transcoder, envoy.grpc_web, envoy.gzip, envoy.health_check, envoy.http_dynamo_filter, envoy.ip_tagging, envoy.lua, envoy.rate_limit, envoy.router, envoy.squash
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.retry_host_predicates: envoy.retry_host_predicates.omit_canary_hosts, envoy.retry_host_predicates.omit_host_metadata, envoy.retry_host_predicates.previous_hosts
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   http_cache_factory: envoy.extensions.http.cache.simple
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.udp_listeners: raw_udp_listener
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.dubbo_proxy.route_matchers: default
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.health_checkers: envoy.health_checkers.redis
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.transport_sockets.upstream: envoy.transport_sockets.alts, envoy.transport_sockets.raw_buffer, envoy.transport_sockets.tap, envoy.transport_sockets.tls, raw_buffer, tls
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.grpc_credentials: envoy.grpc_credentials.aws_iam, envoy.grpc_credentials.default, envoy.grpc_credentials.file_based_metadata
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.filters.listener: envoy.filters.listener.http_inspector, envoy.filters.listener.original_dst, envoy.filters.listener.original_src, envoy.filters.listener.proxy_protocol, envoy.filters.listener.tls_inspector, envoy.listener.http_inspector, envoy.listener.original_dst, envoy.listener.original_src, envoy.listener.proxy_protocol, envoy.listener.tls_inspector
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.thrift_proxy.transports: auto, framed, header, unframed
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.thrift_proxy.protocols: auto, binary, binary/non-strict, compact, twitter
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.retry_priorities: envoy.retry_priorities.previous_priorities
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.dubbo_proxy.serializers: dubbo.hessian2
[2020-04-10 16:39:57.900][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.transport_sockets.downstream: envoy.transport_sockets.alts, envoy.transport_sockets.raw_buffer, envoy.transport_sockets.tap, envoy.transport_sockets.tls, raw_buffer, tls
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.dubbo_proxy.protocols: dubbo
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.access_loggers: envoy.access_loggers.file, envoy.access_loggers.http_grpc, envoy.access_loggers.tcp_grpc, envoy.file_access_log, envoy.http_grpc_access_log, envoy.tcp_grpc_access_log
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.filters.udp_listener: envoy.filters.udp.dns_filter, envoy.filters.udp_listener.udp_proxy
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.resource_monitors: envoy.resource_monitors.fixed_heap, envoy.resource_monitors.injected_resource
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.dubbo_proxy.filters: envoy.filters.dubbo.router
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.thrift_proxy.filters: envoy.filters.thrift.rate_limit, envoy.filters.thrift.router
[2020-04-10 16:39:57.901][6925][info][main] [external/envoy/source/server/server.cc:259]   envoy.stats_sinks: envoy.dog_statsd, envoy.metrics_service, envoy.stat_sinks.dog_statsd, envoy.stat_sinks.hystrix, envoy.stat_sinks.metrics_service, envoy.stat_sinks.statsd, envoy.statsd
[2020-04-10 16:39:57.907][6925][info][main] [external/envoy/source/server/server.cc:340] admin address: 0.0.0.0:9901
[2020-04-10 16:39:57.908][6925][info][main] [external/envoy/source/server/server.cc:459] runtime: layers:
  - name: base
    static_layer:
      {}
  - name: admin
    admin_layer:
      {}
[2020-04-10 16:39:57.909][6925][info][config] [external/envoy/source/server/configuration_impl.cc:103] loading tracing configuration
[2020-04-10 16:39:57.909][6925][info][config] [external/envoy/source/server/configuration_impl.cc:69] loading 0 static secret(s)
[2020-04-10 16:39:57.909][6925][info][config] [external/envoy/source/server/configuration_impl.cc:75] loading 1 cluster(s)
[2020-04-10 16:39:57.910][6925][info][upstream] [external/envoy/source/common/upstream/cluster_manager_impl.cc:171] cm init: all clusters initialized
[2020-04-10 16:39:57.910][6925][info][config] [external/envoy/source/server/configuration_impl.cc:79] loading 1 listener(s)
[2020-04-10 16:39:57.912][6925][info][config] [external/envoy/source/server/configuration_impl.cc:129] loading stats sink configuration
[2020-04-10 16:39:57.912][6925][info][main] [external/envoy/source/server/server.cc:533] all clusters initialized. initializing init manager
[2020-04-10 16:39:57.912][6925][info][config] [external/envoy/source/server/listener_manager_impl.cc:725] all dependencies initialized. starting workers
[2020-04-10 16:39:57.912][6925][info][main] [external/envoy/source/server/server.cc:554] starting main dispatch loop
```

# Testing _Envoy_ proxy

Now that you have _[Envoy](https://www.envoyproxy.io/)_ running, you may take a look on how it balances traffic.

In this example I use _netstat_ command to check if _[Envoy](https://www.envoyproxy.io/)_ has opened port 10000 as stated in the configuration file, and then _curl_ command to check how it balances the traffic between all the _[Nginx](https://www.nginx.com/)_ instances.

```bash
# Login into node-3 using a new terminal and shell.
ζ vagrant ssh node-3
Last login: Fri Apr 10 16:44:12 2020 from 10.0.2.2

# Check the Envoy process has opened port 10000 and it's listening.
[vagrant@localhost ~]$ netstat -putona | grep LISTEN
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
tcp        0      0 0.0.0.0:9901            0.0.0.0:*               LISTEN      5000/envoy           off (0.00/0/0)
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      -                    off (0.00/0/0)
tcp        0      0 0.0.0.0:10000           0.0.0.0:*               LISTEN      5000/envoy           off (0.00/0/0)
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      -                    off (0.00/0/0)
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      -                    off (0.00/0/0)
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      -                    off (0.00/0/0)
tcp6       0      0 :::111                  :::*                    LISTEN      -                    off (0.00/0/0)
tcp6       0      0 :::80                   :::*                    LISTEN      -                    off (0.00/0/0)
tcp6       0      0 :::22                   :::*                    LISTEN      -                    off (0.00/0/0)
tcp6       0      0 ::1:25                  :::*                    LISTEN      -                    off (0.00/0/0)

# Now test that Nginx instances are running directly on the nodes.
[vagrant@localhost ~]$ curl 172.28.128.3
Hello from node 3
[vagrant@localhost ~]$ curl 172.28.128.4
Hello from node 4
[vagrant@localhost ~]$ curl 172.28.128.5
Hello from node 5

# Finally make the same request throuth port 10000 that Envoy provides as a proxy to all the nodes balancing the traffic between them.
[vagrant@localhost ~]$ curl localhost:10000
Hello from node 4
[vagrant@localhost ~]$ curl localhost:10000
Hello from node 5
[vagrant@localhost ~]$ curl localhost:10000
Hello from node 5
[vagrant@localhost ~]$ curl localhost:10000
Hello from node 5
[vagrant@localhost ~]$ curl localhost:10000
Hello from node 3
[vagrant@localhost ~]$ curl localhost:10000
Hello from node 4
```

As you may see, the proxy balances requests asymmetrically as stated in the configuration file.

# Play with _Envoy_ configuration

Now you may proceed to the [next lab](../lab2_integrating_consul_and_envoy) or play around with _[Envoy](https://www.envoyproxy.io/)_ configuration.

If you have time, play a little bit with _[Envoy](https://www.envoyproxy.io/)_ to get a grasp on how it works.

# Tips

You may visit _[Envoy](https://www.envoyproxy.io/)_ configuration at port 9901 of each node that runs _[Envoy](https://www.envoyproxy.io/)_.
The _admin_ console is quite useful to debug and see the stats. Also you may see a dump of the configuration in the *config_dump* section of the _admin_ console.