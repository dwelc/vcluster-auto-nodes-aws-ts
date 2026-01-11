# vCluster Auto Nodes AWS with Tailscale

This is a fork of the [vCluster Auto Nodes AWS quickstart template](https://github.com/loft-sh/vcluster-auto-nodes-aws) with added support for connecting worker nodes to an existing Tailscale network (tailnet).

## Overview

This Terraform-based node provider enables vCluster worker nodes running on AWS EC2 to automatically join your Tailscale network during provisioning. This allows secure remote access to nodes and integration with your existing Tailscale infrastructure without requiring bastion hosts or VPN configurations.

## Limitations

[Issue #1 - Auth Handling](https://github.com/dwelc/vcluster-auto-nodes-aws-ts/issues/1) - At the moment this does not handle AWS authentication. Create a Node Provider from the quickstart template to create the credentials, then edit the node provider templates to point to this repo. 

## Tailscale Configuration

### Prerequisites

1. A Tailscale account with an active tailnet
2. An auth key generated from the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys)

### Generating a Tailscale Auth Key

1. Navigate to Settings > Keys > Auth keys in your Tailscale admin console
2. Click "Generate auth key"
3. Configure the key:
   - **Enable "Reusable"** - Allows the same key to be used for multiple nodes
   - **Enable "Ephemeral"** - Nodes are automatically removed from the tailnet when terminated
   - (Optional) Add the tag `tag:vcluster-worker` for ACL-based access control

### Configuration Options

Tailscale can be configured at two levels:

#### Provider Level (All vClusters)

Add Tailscale properties to your NodeProvider CRD to enable it for all vClusters by default:

```yaml
spec:
  properties:
    tailscale-enabled: 'true'
    tailscale-auth-key: "tskey-auth-xxxxx-xxxxxxxxxxxxxx"

```

#### vCluster Level (All Nodes)

Add Tailscale properties to providers inside a VirtualClusterInstance CRD:

```yaml
privateNodes:
  enabled: true
  autoNodes:
    - provider: dan-aws
      properties:
        tailscale-enabled: 'true'
        tailscale-auth-key: '"tskey-auth-xxxxx-xxxxxxxxxxxxxx"'
      dynamic:
        - name: aws-node-pool
          nodeTypeSelector:
            - property: instance-type
              operator: In
              values:
                - t3.medium
```

### Features

When Tailscale is enabled, worker nodes automatically:

- **Install Tailscale** during initial provisioning via cloud-init
- **Connect to your tailnet** using the provided auth key
- **Accept subnet routes** advertised by other nodes in your tailnet
- **Use a consistent hostname** format: `<vcluster-name>-<index>`
- **Attempt tag-based joining** (falls back to untagged if ACLs aren't configured)

### Security Best Practices

- **Use ephemeral auth keys** - Ensures nodes are automatically removed from the tailnet when terminated
- **Store keys in secrets** - Avoid committing auth keys directly to version control
- **Rotate keys regularly** - Generate new auth keys periodically (requires node replacement)
- **Use tags for access control** - Assign tags like `tag:vcluster-worker` to enable fine-grained ACL rules

### Use Cases

- **Remote debugging** - SSH directly to worker nodes via Tailscale without bastion hosts
- **Service access** - Connect to applications running on worker nodes from your local machine
- **Hybrid networking** - Bridge AWS infrastructure with on-premises resources through Tailscale
- **Secure management** - Access private nodes for maintenance without exposing public IPs

### Example Configuration

Complete VirtualClusterInstance CRD with Tailscale enabled:

```yaml
controlPlane:
  service:
    spec:
      type: LoadBalancer
privateNodes:
  enabled: true
  autoNodes:
    - provider: dan-aws
      properties:
        tailscale-enabled: 'true'
        tailscale-auth-key: tskey-auth-kXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX
      dynamic:
        - name: aws-node-pool
          nodeTypeSelector:
            - property: instance-type
              operator: In
              values:
                - t3.medium
          limits:
            cpu: '10'
            memory: 150Gi
            nvidia.com/gpu: '4'
```

## Additional Resources

For complete setup instructions, authentication methods, and advanced configuration options, refer to the [vCluster Node Provider Documentation](https://www.vcluster.com/docs/platform/administer/node-providers/overview).
