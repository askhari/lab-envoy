Service {
  name = "client"
  port = 8080
  connect {
    sidecar_service {
      proxy {
        upstreams {
          destination_type = "service"
          destination_name = "nginx"
          local_bind_port = 19191
        }
      }
    }
  }
}
