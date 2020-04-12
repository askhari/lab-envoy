kind           = "service-resolver"
name           = "nginx"
default_subset = "primary"
subsets = {
  "primary" = {
    filter = "Service.Tags contains primary"
  }
  "v1" = {
    filter = "Service.Tags contains v1"
  }
  "v2" = {
    filter = "Service.Tags contains v2"
  }
  "secondary" = {
    filter = "(Service.Tags contains v1) and (Service.Tags contains secondary)"
  }
}
