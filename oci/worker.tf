locals {
  worker_pool_defaults = {
    boot_volume_size      = lookup(var.node_shape, "volume_size", 50)
    compartment_id        = var.compartment_id
    image_id              = var.node_image_id
    kubernetes_version    = var.kubernetes_version
    memory                = lookup(var.node_shape, "memory", 6)
    nsg_ids               = []
    ocpus                 = lookup(var.node_shape, "ocpus", 1)
    placement_ads         = var.ad_numbers
    pv_transit_encryption = true
    shape                 = lookup(var.node_shape, "shape", "VM.Standard.A1.Flex")
    size                  = var.worker_pool_size
    subnet_id             = var.worker_subnet_id
    volume_kms_key_id     = var.node_kms_key_id
  }

  worker_pools_with_defaults = { for pool_name, pool in var.worker_pools :
    pool_name => merge(local.worker_pool_defaults, pool)
  }

  worker_pools = { for pool_name, pool in local.worker_pools_with_defaults :
    pool_name => merge(pool, {
      availability_domains = compact([for ad_number in tolist(setintersection(pool.placement_ads, var.ad_numbers)) :
        lookup(local.ad_numbers_to_names, ad_number, null)
      ])

      nsg_ids = [for nsg_id in compact(concat(var.worker_nsg_ids, pool.nsg_ids)) :
        length(regexall("ocid\\d+\\.networksecuritygroup", lower(nsg_id))) == 0 ?
        lookup(local.all_nsg_ids, lower(nsg_id)) : nsg_id
      ]

      subnet_id_final = length(regexall("ocid\\d+\\.subnet", lower(pool.subnet_id))) == 0 ? lookup(local.subnet_ids, lower(pool.subnet_id)) : pool.subnet_id

      volume_kms_key_id_final = coalesce(pool.volume_kms_key_id, "none") != "none" ? pool.volume_kms_key_id : null
    })
  }

  worker_pools_output = { for k, v in oci_containerengine_node_pool.oke_workers : k => v }
  worker_pool_ids     = { for k, v in local.worker_pools_output : k => v.id }
}

resource "oci_containerengine_node_pool" "oke_workers" {
  for_each = local.worker_pools

  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = each.value.compartment_id
  kubernetes_version = each.value.kubernetes_version
  name               = "${var.cluster_name}-${each.key}"
  node_shape         = each.value.shape
  ssh_public_key     = var.ssh_public_key
  freeform_tags      = local.common_tags

  node_shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory
  }

  node_source_details {
    source_type             = "image"
    image_id                = each.value.image_id
    boot_volume_size_in_gbs = each.value.boot_volume_size
  }

  node_config_details {
    size          = each.value.size
    nsg_ids       = each.value.nsg_ids
    freeform_tags = local.common_tags

    is_pv_encryption_in_transit_enabled = each.value.pv_transit_encryption
    kms_key_id                          = each.value.volume_kms_key_id_final

    dynamic "placement_configs" {
      for_each = each.value.availability_domains
      iterator = ad

      content {
        availability_domain = ad.value
        subnet_id           = each.value.subnet_id_final
      }
    }

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  lifecycle {
    ignore_changes = [name, freeform_tags, defined_tags]
  }
}

output "worker_pools" {
  description = "Created worker pools"
  value = { for k, v in local.worker_pools_output : k => {
    id   = v.id
    name = v.name
    size = v.node_config_details[0].size
    shape = v.node_shape
  }}
}

output "worker_pool_nodes" {
  description = "Created worker nodes"
  value = { for pool_name, pool in local.worker_pools_output : pool_name => {
    pool_id = pool.id
    nodes = { for node in pool.nodes :
      node.id => {
        name = node.name
        ip   = node.private_ip
      }
    }
  }}
}
