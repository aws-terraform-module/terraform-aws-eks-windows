# Upgrade from v3.6.1 to v3.7.0

## Overview

This upgrade introduces breaking changes to improve instance type availability and flexibility. Starting from version 3.7.0, instance type variables now expect lists of strings instead of single strings to enable support for multiple instance types for better availability.

## Variable and output changes

1. Added variables:
    - `lin_capacity_type`
    - `win_capacity_type`
    - `capacity_type` in `custom_node_groups`

    - `lin_instance_type_list`
    - `win_instance_type_list`
    - `instance_type_list` in `custom_node_groups`


## New Features

### Multiple Instance Types Support

With this change, you can now specify multiple instance types for better availability:

```hcl
# Multiple instance types for main node groups
lin_instance_type = "m5.large"
win_instance_type = "t3.xlarge"

# If you set both variables, *_instance_type_list takes precedence over *_instance_type
lin_instance_type_list = ["m5.large", "m5.xlarge", "m6i.large"]
win_instance_type_list = ["t3.xlarge", "t3.2xlarge"]

```

```
# Multiple instance types in custom node groups
custom_node_groups = [
  {
    name         = "linux-mixed"
    platform     = "linux"

    # Keep instance_type for backward-compatibility, but if both are supplied
    # instance_type_list is used and instance_type is ignored.
    instance_type = "m5.large"
    instance_type_list = ["m5.large", "m5.xlarge", "m6i.large"]
    
    capacity_type = "SPOT"  # Use spot instances for cost optimization
    # ... other configuration
  }
]

```
