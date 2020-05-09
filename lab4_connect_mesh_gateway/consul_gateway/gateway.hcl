service {
  kind = "mesh-gateway"
  name = "mesh-gateway"
  port = 8443
  checks = [
    {
      name = "Mesh Gateway Listening"
      interval = "10s"
      tcp = ":8443"
      deregister_critical_service_after = "6h"
    }
  ]
}
