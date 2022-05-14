variable "contact_info" {
  type = string
  description = "Contact information to be published in the bridge descriptor."
}

variable "external_network_name" {
  type = string
  description = "Name of the Openstack network that provides Internet access."
  default = "Ext-Net"
}

variable "flavor_name" {
  type = string
  description = "Name of the flavor to use for the compute instance."
  default = "d2-2"
}

variable "image_name" {
  type = string
  description = "Name of the image to use for the compute instance (must be Debian 11 based)."
  default = "Debian 11"
}

variable "region" {
  type = string
  description = "Region to deploy the instance in."
  default = null
}

variable "require_block_device_creation" {
  type = bool
  description = "Create a block device in addition to the server (only needed if not created automatically with instance)."
  default = false
}

variable "ssh_private_key" {
  type = string
  description = "Private SSH key for provisioning."
}

variable "ssh_key" {
  type = string
  description = "Public SSH key for provisioning."
}

variable "ssh_user" {
  type = string
  description = "Username to use for SSH access (must have password-less sudo enabled)."
  default = "debian"
}

variable "distribution_method" {
  type = string
  description = "Bridge distribution method"
  default = "any"

  validation {
    condition     = contains(["https", "moat", "email", "none", "any"], var.distribution_method)
    error_message = "Invalid distribution method. Valid choices are https, moat, email, none or any."
  }
}