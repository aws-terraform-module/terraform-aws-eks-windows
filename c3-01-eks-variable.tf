variable "region" {
  description = "Please enter the region used to deploy this infrastructure"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet ids"
  default     = []
}

variable "eks_cluster_name" {
  type        = string
  description = "Name for the EKS cluster"
  default     = "eks"
}
variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
}

variable "lin_instance_type" {
  description = "Instance size for EKS linux worker nodes. For multiple instance types, use 'lin_instance_type_list'. This variable is ignored if 'lin_instance_type_list' is provided and not empty."
  default     = "m5.large"
  type        = string
}

variable "lin_instance_type_list" {
  description = "A list of instance types for EKS linux worker nodes. If specified, this overrides the 'lin_instance_type' variable."
  default     = []
  type        = list(string)
  validation {
    condition     = alltrue([for t in var.lin_instance_type_list : length(trimspace(t)) > 0])
    error_message = "lin_instance_type_list cannot contain empty or whitespace-only strings."
  }
}

# eks autoscaling
variable "lin_min_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "lin_desired_size" {
  description = "Desired capacity for Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "lin_max_size" {
  description = "Maximum number of Linux nodes for the EKS."
  default     = 2
  type        = number
}

variable "lin_ami_type" {
  description = "AMI type for the Linux Nodes."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "lin_capacity_type" {
  description = "Type of capacity associated with the EKS Linux Node Group. Valid values: `ON_DEMAND`, `SPOT`"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND","SPOT"], var.lin_capacity_type)
    error_message = "lin_capacity_type must be one of: ON_DEMAND, SPOT."
  }
}

# # eks autoscaling for windows
variable "win_min_size" {
  description = "Minimum number of Windows nodes for the EKS"
  default     = 1
  type        = number
}

variable "win_desired_size" {
  description = "Desired capacity for Windows nodes for the EKS."
  default     = 1
  type        = number
}

variable "win_max_size" {
  description = "Maximum number of Windows nodes for the EKS."
  default     = 2
  type        = number
}

variable "win_instance_type" {
  description = "Instance size for EKS windows worker nodes. For multiple instance types, use 'win_instance_type_list'. This variable is ignored if 'win_instance_type_list' is provided and not empty."
  default     = "m5.large"
  type        = string
}

variable "win_instance_type_list" {
  description = "A list of instance types for EKS windows worker nodes. Overrides 'win_instance_type' if specified."
  default     = []
  type        = list(string)
  validation {
    condition     = alltrue([for t in var.win_instance_type_list : length(trimspace(t)) > 0])
    error_message = "win_instance_type_list cannot contain empty or whitespace-only strings."
  }
}

variable "win_capacity_type" {
  description = "Type of capacity associated with the EKS Windows Node Group. Valid values: `ON_DEMAND`, `SPOT`"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND","SPOT"], var.win_capacity_type)
    error_message = "win_capacity_type must be one of: ON_DEMAND, SPOT."
  }
}

variable "windows_ami_type" {
  description = "AMI type for the Windows Nodes."
  type        = string
  default     = "WINDOWS_CORE_2022_x86_64"
}


variable "node_host_key_name" {
  description = "Please enter the name of the SSH key pair that should be assigned to the worker nodes of the cluster"
  type        = string
}

variable "disable_windows_defender" {
  description = "Flag to disable Windows Defender. Set to true to disable."
  type        = bool
  default     = false # Set the default as per your requirement
}

variable "custom_node_groups" {
  description = "List of custom node group configurations"
  type = list(object({
    name                     = string
    platform                 = string
    windows_ami_type         = optional(string, null)
    lin_ami_type             = optional(string, null)
    subnet_ids               = optional(list(string), [])
    instance_type             = optional(string, "")            # Legacy single type
    instance_type_list        = optional(list(string), [])   # Preferred multiple types
    capacity_type            = optional(string, "ON_DEMAND")
    desired_size             = number
    max_size                 = number
    min_size                 = number
    disable_windows_defender = optional(bool, false)
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    labels = optional(map(string), {})
  }))
  default = []

  validation {
    condition = alltrue([
      for ng in var.custom_node_groups : (
        # Must define at least one instance type
        length(coalesce(ng.instance_type_list, [])) > 0 ||
        (ng.instance_type != null && trimspace(ng.instance_type) != "")
      ) &&
      # Capacity type must be valid
      contains(["ON_DEMAND","SPOT"], try(ng.capacity_type, "ON_DEMAND")) &&
      # All strings in instance_type_list must be non-empty
      alltrue([for t in coalesce(ng.instance_type_list, []) : trimspace(t) != ""])
    ])
    error_message = <<EOT
      Each custom_node_groups element must:
      1) Define at least one instance type (instance_type or instance_type_list).
      2) Use capacity_type ON_DEMAND or SPOT.
      3) Avoid empty strings in instance_type_list.
      EOT
  }
}


###############
### CoreDNS ###
###############
variable "enabled_coredns_auto_scaling" {
  description = "Enable CoreDNS auto scaling"
  type        = bool
  default     = true

}
variable "coredns_max_replicas" {
  description = "Maximum number of replicas for the CoreDNS auto scaling"
  type        = number
  default     = 20
}

variable "coredns_min_replicas" {
  description = "Minimum number of replicas for the CoreDNS auto scaling"
  type        = number
  default     = 2
}

variable "coredns_addon_version" {
  description = "The version of CoreDNS to deploy. Specify a version string like \"v1.11.1-eksbuild.9\". If not provided, the latest available version will be used."
  type        = string
  default     = null

}

variable "control_plane_logs" {
  description = "Enable the control plane logs include: API server, Audit, Authenticator, Controller manager, Scheduler"
  type = bool
  default = false
}

