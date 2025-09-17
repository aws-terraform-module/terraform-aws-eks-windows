# Upgrade from v3.7.x to v4.x

## Overview

Version 4.0.0 introduces a **breaking change** to the `taints` structure in `custom_node_groups`. The taints field has been changed from a list to a map structure, and the `value` field is now optional.

## Breaking Changes

### ⚠️ Taints Structure Change in `custom_node_groups`

The `taints` field in `custom_node_groups` has been changed from a list to a map structure, and the `value` field is now optional.

**Before (v3.7.x):**
```hcl
custom_node_groups = [
  {
    name = "my-group"
    platform = "linux"
    # ... other required fields
    taints = [
      {
        key    = "dedicated"
        value  = "true"        # Required
        effect = "NO_SCHEDULE"
      },
      {
        key    = "special"
        value  = "workload"    # Required
        effect = "NO_EXECUTE"
      }
    ]
  }
]
```

**After (v4.0.0):**
```hcl
custom_node_groups = [
  {
    name = "my-group"
    platform = "linux"
    # ... other required fields
    taints = {
      dedicated = {
        key    = "dedicated"
        value  = "true"        # Optional
        effect = "NO_SCHEDULE"
      }
      special = {
        key    = "special"
        # value is now optional - can be omitted
        effect = "NO_EXECUTE"
      }
    }
  }
]
```

### Migration Steps
> Prerequisite: Terraform CLI v1.3 or newer (required for `optional(...)` object attributes and optional attribute defaults).

1. **Change structure**: Convert `taints = [...]` to `taints = {...}`
2. **Add map keys**: Wrap each taint object in a map with a unique key (typically the same as the `key` field)
3. **Remove empty values**: Remove `value` fields that are empty or null (they're now optional)
4. **Ensure uniqueness**: Make sure each taint has a unique map key

## Example Migration

Here's a complete example showing the migration:

**Old configuration:**
```hcl
custom_node_groups = [
  {
    name          = "active-mq-group"
    platform      = "linux"
    # ... other fields
    min_size      = 1
    max_size      = 1
    desired_size  = 1
    taints = [
      {
        key    = "active-mq"
        value  = "true"
        effect = "NO_EXECUTE"
      }
    ]
    labels = {
      "deployment" : "active-mq"
    }
  }
]
```

**New configuration:**
```hcl
  custom_node_groups = [
    {
      name          = "active-mq-group"
      platform      = "linux"
      # ... other fields
      min_size      = 1
      max_size      = 1
      desired_size  = 1
      taints = {
        active_mq = {
          key    = "active-mq"
          value  = "true"
          effect = "NO_EXECUTE"
        }
      }
      labels = {
        "deployment" : "active-mq"
      }
    }
  ]
```

## Backward Compatibility

This is a **breaking change** and requires manual migration of existing configurations. There is no automatic migration path provided.