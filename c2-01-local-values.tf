# # Define Local Values in Terraform
# locals {
#   effective_win_subnet_ids = length(var.extra_subnet_ids) > 0 ? var.extra_subnet_ids : var.private_subnet_ids
# }
locals {
  linux_ami_type_map = {
    "amazon-linux-2023" = "AL2023_x86_64"
    "bottlerocket"      = "BOTTLEROCKET_x86_64"
  }

  linux_ami_type = local.linux_ami_type_map[var.linux_ami_type]
}
