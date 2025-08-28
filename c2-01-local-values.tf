# # Define Local Values in Terraform
# locals {
#   effective_win_subnet_ids = length(var.extra_subnet_ids) > 0 ? var.extra_subnet_ids : var.private_subnet_ids
# }


## Local Values for EKS
locals {
  # Determine instance types, prioritizing the list variable over the single string variable
  linux_instance_types   = length(coalesce(var.lin_instance_type_list, [])) > 0 ? coalesce(var.lin_instance_type_list, []) : (var.lin_instance_type != null ? [var.lin_instance_type] : [])
  windows_instance_types = length(coalesce(var.win_instance_type_list, [])) > 0 ? coalesce(var.win_instance_type_list, []) : (var.win_instance_type != null ? [var.win_instance_type] : [])
}