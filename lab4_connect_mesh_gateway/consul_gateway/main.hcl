datacenter = "envoy-lab"
primary_datacenter = "envoy-lab"
server = false
bind_addr = "172.28.128.5"
ports {
  grpc = 8502
}
addresses {
  http = "172.28.128.5"
}
data_dir = "/opt/consul_client/lib"
log_file = "/opt/consul_client/logs/consul.log"
node_name = "node5"
start_join = ["172.28.128.3","172.28.128.4"]
retry_join = ["172.28.128.3","172.28.128.4"]
connect {
  enabled = true
}
