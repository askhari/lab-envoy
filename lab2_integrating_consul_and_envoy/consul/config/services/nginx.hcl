Service {
  Name = "nginx"
  Tags = ["primary","v1"]
  Port = 80
  Meta {
    nginx = "1.0"
  }
  connect {
    sidecar_service {
    }
  }
}
