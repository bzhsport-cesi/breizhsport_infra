
variable "api_token" {
  description = "API token for the Warren provider"
  type        = string
}

variable "vm_prefix" {
  description = "Prefix for VM name"
  default     = "denvr"
}

variable "ssh_public_key" {
  description = "public SSH key name for the instances"
  type        = string
}

variable "ssh_private_key" {
  description = "private SSH key name for the instances"
  type        = string
}

variable "username" {
  description = "Username for the instances"
  type        = string
}

variable "os_name" {
  description = "Name of the OS for the instances"
  type        = string
}

variable "os_version" {
  description = "Version of the OS for the instances"
  type        = string
}

variable "vm_number" {
  description = "Number of instances to manage"
  type        = number
}

variable "cpu_number" {
  description = "Number of vCPU for the instances"
  type        = number
}

variable "ram_number" {
  description = "Number of RAM for the instances"
  type        = number
}

variable "disk_size" {
  description = "Number of RAM for the instances"
  type        = number
}

variable "network_name" {
  description = "Name of the network to connect created VMs"
  type        = string
}

variable "front_image_tag" {
  description = "Tag de l'image Docker front à déployer"
  type        = string
  default     = "ghcr.io/owner/front:latest"
}

variable "back_image_tag" {
  description = "Tag de l'image Docker back à déployer"
  type        = string
  default     = "ghcr.io/owner/back:latest"
}