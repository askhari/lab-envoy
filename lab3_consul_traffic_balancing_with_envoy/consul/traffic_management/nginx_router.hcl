[vagrant@localhost traffic]$ cat nginx_router.hcl 
kind = "service-router"
name = "nginx"
routes = [
  {
    match {
      http {
        path_prefix = "/secondary"
      }
    }
    destination {
      service_subset = "secondary"
      prefix_rewrite = "/"
    }
  },
  {
    match {
      http {
        header = [
          {
            name  = "x-service-version"
            exact = "v1"
          },
        ]
      }
    }
    destination {
      service_subset = "primary"
    }
  },
  {
    match {
      http {
        header = [
          {
            name  = "x-service-version"
            exact = "v2"
          },
        ]
      }
    }
    destination {
      service_subset = "v2"
    }
  },
]
