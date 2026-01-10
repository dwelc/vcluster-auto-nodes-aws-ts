variable "vcluster" {
  description = "vCluster configuration object passed from the platform"
  type = object({
    instance = object({
      metadata = object({
        name      = string
        namespace = string
      })
    })
    nodeType = object({
      spec = object({
        properties = map(string)
      })
    })
    nodeEnvironment = object({
      outputs = object({
        infrastructure = map(any)
      })
    })
    userData = string
  })
  sensitive = true
}
