# Upgrade from v4.0.x to v4.1.x

## Overview

Version 4.1 introduces improvements to control-plane logging, add-on ordering for first-time installs, CoreDNS update safety, and updates the default Windows AMI type.

No breaking variable renames were made; review the behavior changes and adopt the recommended migration steps below.

## Changes

### New: control plane logs toggle

- Added input `control_plane_logs` (bool, default: `false`).
- When set to `true`, the module enables control-plane logging by mapping to `enabled_log_types` in the upstream EKS module with:
  - `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`.

Example:
```hcl
module "eks-windows" {
  # ...existing inputs
  control_plane_logs = true
}
```

### New: initial deployment ordering

- Added input `create_new` (bool, default: `true`).
- For first-time deployments, this ensures the VPC CNI and kube-proxy add-ons are applied before compute (`before_compute = true`).
- For upgrades or subsequent changes, you can set `create_new = false` to avoid plan diffs related to ordering.

Example:
```hcl
module "eks-windows" {
  # ...existing inputs
  create_new = true # first-time install; set false for upgrades
}
```

### Safer CoreDNS updates

- CoreDNS add-on now preserves cluster-side changes by default:
  - `resolve_conflicts_on_update = "PRESERVE"`.
- You can optionally pin a version via `coredns_addon_version` and control autoscaling via:
  - `enabled_coredns_auto_scaling` (default: `true`)
  - `coredns_min_replicas` (default: `2`)
  - `coredns_max_replicas` (default: `20`)

### Default Windows AMI type updated

- `windows_ami_type` default changed to `WINDOWS_CORE_2022_x86_64`.

## Migration steps

1. Review cluster version and region support for Windows Server 2022 AMIs. If you need the previous default, set:
   ```hcl
   windows_ami_type = "WINDOWS_CORE_2019_x86_64"
   ```
2. For first-time installs, keep `create_new = true` (default). For existing clusters or upgrades, set:
   ```hcl
   create_new = false
   ```
   to minimize plan noise while preserving behavior.
3. Enable control-plane logs as needed:
   ```hcl
   control_plane_logs = true
   ```
4. If CoreDNS has cluster-specific ConfigMap customizations, no action is required; updates now default to `PRESERVE`. If you explicitly need to overwrite, adjust in code to `OVERWRITE` before applying (advanced scenario).

## Additional changes

### Variable and output changes

1. Added variables:

    - `create_new`
    - `control_plane_logs`

## References

- Upstream EKS module changes and log types naming in v21: [Upgrade guide](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/UPGRADE-21.0.md)
- PR implementing these changes in this module: [#121](https://github.com/aws-terraform-module/terraform-aws-eks-windows/pull/121)


