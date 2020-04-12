kind = "service-splitter"
name = "nginx"
splits = [
  {
    weight         = 10
    service_subset = "v1"
  },
  {
    weight         = 10
    service_subset = "v2"
  },
  {
    weight         = 10
    service_subset = "primary"
  },
  {
    weight         = 70
    service_subset = "secondary"
  },
]
