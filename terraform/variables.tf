
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
  default     = "ghcr.io/bzhsport-cesi/breizhsport_front:master"
}

variable "registry_username" {
  description = "GitHub Container Registry username"
  type        = string
}

variable "registry_token" {
  description = "GitHub Container Registry token/password"
  type        = string
}

variable "frontend_domain" {
  description = "Nom de domaine pointant vers le frontend"
  type        = string
}

variable "letsencrypt_email" {
  description = "Adresse e-mail pour Let's Encrypt"
  type        = string
}

variable "cloudflare_api_token" {
  description = "API Token for Cloudflare"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}