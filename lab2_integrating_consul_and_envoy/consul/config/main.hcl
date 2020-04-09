datacenter = "envoy-lab"
server = true
bind_addr = "172.28.128.3"
ports {
  grpc = 8502
}
addresses {
  http = "172.28.128.3"
}
data_dir = "/opt/consul/lib"
log_file = "/opt/consul/logs/logsconsul.log"
node_name = "node3"
bootstrap_expect = 3
start_join = ["172.28.128.3","172.28.128.4","172.28.128.5"]
retry_join = ["172.28.128.3","172.28.128.4","172.28.128.5"]
connect {
  enabled = true
}
