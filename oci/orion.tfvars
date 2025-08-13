environment = "prod"

# Auth
tenancy_id           = "ocid1.tenancy.oc1..aaaaaaaaawzh7fbu2acp7omro2nbce27tvzdwqllbrvllfdj4asnkgml6q7a"
compartment_id       = "ocid1.compartment.oc1..aaaaaaaavwt6xfkj4nz4awqhmzkkpxcj4iex3labledxuj3dcqivhq4tdbba"
user_id              = "ocid1.user.oc1..aaaaaaaa4uncc2zag5lvpbyvevvhx6wllybeuvzdkjkpqpe3vlx5ymggfkgq"
api_fingerprint      = "2a:e9:7a:f3:c6:ca:09:d6:4e:cd:a6:e8:fc:f1:3d:8c"
api_private_key_path = "/Users/sebby/.oci/oci_api_key.pem"
region               = "us-ashburn-1"

# Network
vcn_cidr = "10.0.0.0/16"
subnets = {
  cp     = { cidr = "10.0.1.0/30" }
  worker = { cidr = "10.0.2.0/24" }
  int_lb = { cidr = "10.0.3.0/24" }
  pub_lb = { cidr = "10.0.4.0/24" }
}

allow_rules_public_lb = {
  "Allow TCP ingress to public load balancers for SSL traffic from anywhere" : {
    protocol = 6, port = 443, source = "0.0.0.0/0", source_type = "CIDR_BLOCK",
  },
}

# Cluster
cluster_name                   = "orion"
cluster_endpoint_allowed_cidrs = ["173.48.211.185/32"]
cluster_endpoint_is_public     = true
cluster_pods_cidr              = "10.244.0.0/16"
cluster_services_cidr          = "10.96.0.0/16"

# Node
ad_numbers = [1, 2, 3]
worker_pools = {
  vm-free = {
    size = 4,
  },
}

node_shape = {
  shape       = "VM.Standard.A1.Flex"
  ocpus       = 1
  memory      = 6
  volume_size = 50
}

# Oracle Linux 8 aarch64-2025.06.17-0 1.33.1
node_image_id = "ocid1.image.oc1.iad.aaaaaaaaerx2ubtnjyn6iheofmp2tffupz4527crv5kj5f6t22ombs4qnzba"

# Tags
freeform_tags = {
  "Owner" = "binaryfields"
}
