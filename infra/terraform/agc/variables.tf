variable "name" {
  type        = string
  description = "Name of the Application Gateway for Containers (trafficController). Must match pattern ^[A-Za-z0-9]([A-Za-z0-9-_.]{0,62}[A-Za-z0-9])?$"

  validation {
    condition     = can(regex("^[A-Za-z0-9]([A-Za-z0-9-_.]{0,62}[A-Za-z0-9])?$", var.name))
    error_message = "Name must start and end with alphanumeric character, may contain hyphens, underscores, periods. Max 64 chars."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure resource group where AGC resources will be created"
}

variable "location" {
  type        = string
  description = "Azure region for AGC resources. Must be one of the 23 AGC-supported regions. See docs/agc-region-matrix.md"
}

variable "subnet_id" {
  type        = string
  description = "Azure resource ID of the subnet delegated to Microsoft.ServiceNetworking/trafficControllers. Caller must pre-create subnet with delegation."

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.subnet_id))
    error_message = "subnet_id must be a valid Azure subnet resource ID"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to AGC resources"
  default     = {}
}
