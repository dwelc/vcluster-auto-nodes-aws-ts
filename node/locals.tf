locals {
  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  vcluster_namespace = nonsensitive(var.vcluster.instance.metadata.namespace)

  subnet_id             = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["private_subnet_ids"][random_integer.subnet_index.result])
  instance_type         = nonsensitive(var.vcluster.nodeType.spec.properties["instance-type"])
  security_group_id     = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["security_group_id"])
  instance_profile_name = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["instance_profile_name"])
  cluster_tag           = nonsensitive(var.vcluster.nodeEnvironment.outputs.infrastructure["cluster_tag"])

  # Tailscale configuration
  tailscale_enabled  = try(tobool(var.vcluster.nodeType.spec.properties["tailscale-enabled"]), false)
  tailscale_auth_key = try(var.vcluster.nodeType.spec.properties["tailscale-auth-key"], "")

  # Generate Tailscale user data if enabled
  tailscale_user_data = local.tailscale_enabled && local.tailscale_auth_key != "" ? templatefile(
    "${path.module}/scripts/tailscale-init.sh.tftpl",
    {
      tailscale_auth_key = local.tailscale_auth_key
      hostname          = format("%s-%s", local.vcluster_name, random_integer.subnet_index.result)
    }
  ) : ""

  # Combine Tailscale user data with custom user data
  # If both exist, join with newline; otherwise use whichever exists
  combined_user_data = join("\n", compact([
    local.tailscale_user_data,
    var.vcluster.userData
  ]))

  # Final user data - set to null if empty to avoid unnecessary updates
  user_data = local.combined_user_data != "" ? local.combined_user_data : null
}
