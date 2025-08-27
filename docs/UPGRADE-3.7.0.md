# Upgrade from v3.6.1 to v3.7.0

## Overview

This upgrade introduces breaking changes to improve instance type availability and flexibility. Starting from version 3.7.0, instance type variables now expect lists of strings instead of single strings to enable support for multiple instance types for better availability.

## List of backwards incompatible changes

- `lin_instance_type`, `win_instance_type`, `instance_type` now expect lists instead of single strings

| Variable | Before (v3.6.1) | After (v3.7.0) | Description |
|----------|------------------|-----------------|-------------|
| `lin_instance_type` | `"t3.medium"` | `["t3.medium"]` | Linux node group instance type(s) |
| `win_instance_type` | `"t3.xlarge"` | `["t3.xlarge"]` | Windows node group instance type(s) |
| `instance_type` in `custom_node_groups` | `"t3.large"` | `["t3.large"]` | Custom node group instance type(s) |

### Variable and output changes

1. Added variables:
    - `lin_capacity_type`
    - `win_capacity_type`
    - `capacity_type` in `custom_node_groups`

### Migration Examples

#### Before (v3.6.1)
```hcl
module "eks-windows" {
  source = "aws-terraform-module/eks-windows/aws"
  version = "3.6.1"
  
  lin_instance_type = "m5.2xlarge"
  win_instance_type = "t3.xlarge"
  
  custom_node_groups = [
    {
      name         = "windows-group"
      platform     = "windows"
      instance_type = "t3.large"
      # ... other configuration
    }
  ]
}
```

#### After (v3.7.0)
```hcl
module "eks-windows" {
  source = "aws-terraform-module/eks-windows/aws"
  version = "3.7.0"
  
  lin_instance_type = ["m5.2xlarge"]
  win_instance_type = ["t3.xlarge"]
  
  # New capacity type variables for v3.7.0
  lin_capacity_type = "ON_DEMAND"  # or "SPOT"
  win_capacity_type = "ON_DEMAND"  # or "SPOT"
  
  custom_node_groups = [
    {
      name         = "windows-group"
      platform     = "windows"
      instance_type = ["t3.large"]
      capacity_type = "ON_DEMAND"  # or "SPOT"
      # ... other configuration
    }
  ]
}
```

## New Features

### Multiple Instance Types Support

With this change, you can now specify multiple instance types for better availability:

```hcl
# Multiple instance types for main node groups
lin_instance_type = ["m5.large", "m5.xlarge", "m6i.large"]
win_instance_type = ["t3.xlarge", "t3.2xlarge"]

# Multiple instance types in custom node groups
custom_node_groups = [
  {
    name         = "linux-mixed"
    platform     = "linux"
    instance_type = ["m5.large", "m5.xlarge", "m6i.large"]
    capacity_type = "SPOT"  # Use spot instances for cost optimization
    # ... other configuration
  }
]
