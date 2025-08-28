# # Define Local Values in Terraform
# locals {
#   effective_win_subnet_ids = length(var.extra_subnet_ids) > 0 ? var.extra_subnet_ids : var.private_subnet_ids
# }


## Local Values for EKS
locals {
  # Determine instance types, prioritizing the list variable over the single string variable
  linux_instance_types   = length(var.lin_instance_type_list) > 0 ? var.lin_instance_type_list : [var.lin_instance_type]
  windows_instance_types = length(var.win_instance_type_list) > 0 ? var.win_instance_type_list : [var.win_instance_type]

  # Create a map of instance types for each custom node group to improve readability.
  # This logic prioritizes the '_list' variable, falling back to the string variable for backward compatibility.
  custom_node_group_instance_types = {
    for ng in var.custom_node_groups : ng.name => length(ng.instance_type_list) > 0 ? ng.instance_type_list : (ng.instance_type != null ? [ng.instance_type] : [])
  }
}