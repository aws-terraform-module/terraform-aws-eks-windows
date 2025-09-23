# data "aws_ami" "win_ami" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["Windows_Server-2019-English-Core-EKS_Optimized-${var.eks_cluster_version}-*"]
#   }
# }

# Fetch CIDR blocks for each subnet ID
data "aws_subnet" "subnets" {
  for_each = toset(concat(var.private_subnet_ids, var.public_subnet_ids))

  id = each.value
}

module "eks" {
  source                 = "terraform-aws-modules/eks/aws"
  version                = "21.2.0"
  name                   = var.eks_cluster_name
  kubernetes_version     = var.eks_cluster_version
  subnet_ids             = concat(var.private_subnet_ids, var.public_subnet_ids)
  vpc_id                 = var.vpc_id
  endpoint_public_access = true

  node_security_group_additional_rules = {
    ingress_subnet_ids_all = {
      description = "Node to node all ports/protocols in subnet IDs assigned to install EKS"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [for s in data.aws_subnet.subnets : s.cidr_block]
    }
  }

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = merge(
    {
      linux = {
        tags = {
          "k8s.io/cluster-autoscaler/enabled"                 = "true",
          "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
        }

        ami_type       = var.lin_ami_type
        instance_types = local.linux_instance_types
        min_size       = var.lin_min_size
        max_size       = var.lin_max_size
        desired_size   = var.lin_desired_size
        key_name       = var.node_host_key_name
        capacity_type  = var.lin_capacity_type

        ebs_optimized = true
        block_device_mappings = {
          root = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = var.linux_volume_size
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 125
              encrypted             = true
              delete_on_termination = true
            }
          }
        }
      }
      windows = {
        ami_type = var.windows_ami_type
        tags = {
          "k8s.io/cluster-autoscaler/enabled"                 = "true",
          "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
        }
        instance_types = local.windows_instance_types
        min_size       = var.win_min_size
        max_size       = var.win_max_size
        desired_size   = var.win_desired_size
        key_name       = var.node_host_key_name
        capacity_type  = var.win_capacity_type

        # #   #####################
        # #   #### BOOTSTRAPING ###
        # #   #####################
        pre_bootstrap_user_data = (var.disable_windows_defender ? <<-EOT
        <powershell>
        # Add Windows Defender exclusion 
        Set-MpPreference -DisableRealtimeMonitoring $true
        
        </powershell>
        EOT
        : "")


        ebs_optimized = true
        block_device_mappings = {
          root = {
            device_name = "/dev/sda1"
            ebs = {
              volume_size           = var.windows_volume_size
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 125
              encrypted             = true
              delete_on_termination = true
            }
          }
        }
      }
    },

    { for ng in var.custom_node_groups : ng.name => {
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }

      taints = ng.taints
      labels = ng.labels

      # Conditional AMI type based on the platform and custom configuration
      ami_type = ng.platform == "windows" ? (
        ng.windows_ami_type != null ? ng.windows_ami_type : var.windows_ami_type
        ) : ng.platform == "linux" ? (
        ng.lin_ami_type != null ? ng.lin_ami_type : var.lin_ami_type
      ) : null
      subnet_ids = length(ng.subnet_ids) > 0 ? ng.subnet_ids : concat(var.private_subnet_ids, var.public_subnet_ids),

      # Try instance_type_list first, then instance_type, finally empty list
      instance_types = length(coalesce(ng.instance_type_list, [])) > 0 ? coalesce(ng.instance_type_list, []) : (ng.instance_type != null ? [ng.instance_type] : [])

      min_size     = ng.min_size
      max_size     = ng.max_size
      desired_size = ng.desired_size
      key_name     = var.node_host_key_name

      capacity_type = ng.capacity_type

      # #   #####################
      # #   #### BOOTSTRAPING ###
      # #   #####################
      pre_bootstrap_user_data = (
        ng.disable_windows_defender == true && ng.platform == "windows" ? <<-EOT
            <powershell>
            # Add Windows Defender exclusion 
            Set-MpPreference -DisableRealtimeMonitoring $true
            
            </powershell>
            EOT
        : ""
      )

      ebs_optimized = true
      block_device_mappings = {
        root = {
          device_name = ng.platform == "windows" ? "/dev/sda1" : "/dev/xvda",
          ebs = {
            volume_size           = ng.volume_size
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
      }
    }
  )

  addons = {
    kube-proxy = {
      most_recent    = true
      before_compute = var.create_new
    }
    vpc-cni = {
      configuration_values = jsonencode({
        enableWindowsIpam = "true"
      })
      most_recent    = true
      resolve_conflicts = "PRESERVE"
      before_compute = var.create_new
    }
    coredns = {
      addon_version               = try(var.coredns_addon_version, null)
      most_recent                 = true //module will fallback to most_recent if addon_version is not provided
      resolve_conflicts_on_update = "PRESERVE"
      configuration_values = jsonencode({
        autoScaling = {
          enabled     = var.enabled_coredns_auto_scaling
          minReplicas = var.coredns_min_replicas
          maxReplicas = var.coredns_max_replicas
        }
      })
    }
  }

  enabled_log_types = var.control_plane_logs ? [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ] : []
}
