# --- General ---

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "freeform_tags" {
  description = "Freeform tags to apply to resources"
  type        = map(string)
  default     = {}
}

# --- Auth ---

variable "tenancy_id" {
  description = "The tenancy id of the OCI Cloud Account in which to create the resources."
  type        = string
}

variable "compartment_id" {
  description = "The compartment id where resources will be created."
  type        = string
}

variable "user_id" {
  description = "User ID"
  type        = string
}

variable "api_fingerprint" {
  description = "Fingerprint of OCI API private key"
  type        = string
}

variable "api_private_key_path" {
  description = "Path to OCI API private key"
  type        = string
}

variable "region" {
  description = "The OCI region where the resources will be created."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for accessing worker nodes"
  type        = string
  default     = ""
}

# --- Network ---

variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  type = map(object({
    cidr         = optional(string)
    display_name = optional(string)
    dns_label    = optional(string)
  }))
}

# --- Cluster ---

variable "cluster_name" {
  description = "Cluster name (prefix for all resource names)"
  type        = string
}

variable "cluster_endpoint_allowed_cidrs" {
  description = "CIDR blocks allowed to access cluster API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_is_public" {
  description = "Whether cluster endpoint should be public"
  type        = bool
  default     = true
}

variable "cluster_kms_key_id" {
  description = "KMS key OCID for encryption (optional)"
  type        = string
  default     = "none"
}

variable "cluster_pods_cidr" {
  description = "CIDR block for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "cluster_services_cidr" {
  description = "CIDR block for services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to deploy."
  type        = string
  default     = "v1.33.1"
}

# --- Workers ---

variable "ad_numbers" {
  description = "List of OCID Availability Domains indexes."
  type        = list(number)
}

variable "worker_pools" {
  description = "Tuple of OKE worker pools where each key maps to the OCID of an OCI resource, and value contains its definition."
  type        = any
  default     = {}
}

variable "worker_pool_size" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 0
}

variable "worker_subnet_id" {
  description = "FIXME"
  type        = string
  default     = "worker"
}

variable "worker_nsg_ids" {
  description = "An additional list of network security group (NSG) IDs for node security. Combined with 'nsg_ids' specified on each pool."
  type        = list(string)
  default     = ["worker"]
}

variable "node_image_id" {
  description = "Node O/S image OCID. Leave empty to use latest Oracle Linux image."
  type        = string
}

variable "node_shape" {
  description = "Default shape of the created worker instance when unspecified on a pool."
  type = object({
    shape       = string,
    ocpus       = number,
    memory      = number,
    volume_size = number,
  })
  default = {
    shape       = "VM.Standard.A1.Flex",
    ocpus       = 1,
    memory      = 6,
    volume_size = 50
  }
}

variable "node_kms_key_id" {
  description = "KMS key OCID for encryption (optional)"
  type        = string
  default     = "none"
}

# --- Security ---

variable "allow_rules_cp" {
  type    = any
  default = {}
}
variable "allow_rules_internal_lb" {
  type    = any
  default = {}
}
variable "allow_rules_pods" {
  type    = any
  default = {}
}
variable "allow_rules_public_lb" {
  type    = any
  default = {}
}
variable "allow_rules_workers" {
  type    = any
  default = {}
}
