locals {
  vcluster_name      = nonsensitive(var.vcluster.name)
  vcluster_namespace = nonsensitive(var.vcluster.namespace)

  subnet_id             = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["private_subnet_ids"][random_integer.subnet_index.result])
  instance_type         = nonsensitive(var.vcluster.nodeType.spec.properties["instance-type"])
  security_group_id     = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["security_group_id"])
  instance_profile_name = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["instance_profile_name"])
  cluster_tag           = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["cluster_tag"])

  # Tailscale configuration
  # var.vcluster.properties contains merged properties from NodeProvider and VirtualClusterInstance
  tailscale_enabled  = try(tobool(var.vcluster.properties["tailscale-enabled"]), false)
  tailscale_auth_key = try(var.vcluster.properties["tailscale-auth-key"], "")

  # Generate Tailscale user data if enabled
  tailscale_user_data = local.tailscale_enabled && local.tailscale_auth_key != "" ? templatefile(
    "${path.module}/scripts/tailscale-init.sh.tftpl",
    {
      tailscale_auth_key = local.tailscale_auth_key
      hostname          = format("%s-%s", local.vcluster_name, random_integer.subnet_index.result)
    }
  ) : ""

  # Prepend Tailscale as a single-line runcmd item, matching the indent of vCluster's first item
  # (vCluster 0.37 emits items at column 0; older versions indented them)
  user_data = local.tailscale_enabled && local.tailscale_auth_key != "" ? (
    var.vcluster.userData != "" ? replace(
      var.vcluster.userData,
      "/runcmd:\\n([ \\t]*)- /",
      "runcmd:\n$1- echo ${base64encode(local.tailscale_user_data)} | base64 -d | bash\n$1- "
    ) : var.vcluster.userData
  ) : (var.vcluster.userData != "" ? var.vcluster.userData : null)
}
