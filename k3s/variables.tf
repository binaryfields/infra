variable "hcloud_token" {
  description = "Cloud token"
}

variable "cluster_name" {
  description = "Cluster name (prefix for all resource names)"
}

variable "network_zone" {
  description = "Network region"
}

variable "location" {
  description = "Location where resources reside"
}

variable "datacenter" {
  description = "Datacenter where servers reside"
}

variable "instance_image" {
  description = "Node O/S image"
  default     = "debian-12"
}

variable "gateway_image" {
  description = "Gateway O/S image"
  default     = "debian-12"
}

variable "gateway_private_ip" {
  description = "Gateway private IP"
}

variable "gateway_type" {
  description = "Gateway type"
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
}

variable "master_type" {
  description = "K8s master type"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "node_type" {
  description = "K8s worker node type"
}

variable "node_volume_size" {
  description = "Size of node's data volume"
  type        = number
}

variable "private_interface" {
  description = "Name of the private network interface"
  default = "enp7s0"
}

variable "ssh_key_name" {
  description = "Public SSH key name"
}
