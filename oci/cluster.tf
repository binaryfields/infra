resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = oci_core_vcn.oke_vcn.id
  kms_key_id         = coalesce(var.cluster_kms_key_id, "none") != "none" ? var.cluster_kms_key_id : null
  freeform_tags      = local.common_tags

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = var.cluster_endpoint_is_public
    subnet_id            = lookup(local.subnet_ids, "cp")
    nsg_ids              = [lookup(local.all_nsg_ids, "cp")]
  }

  options {
    service_lb_subnet_ids = [lookup(local.subnet_ids, "pub_lb")]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    admission_controller_options {
      is_pod_security_policy_enabled = false
    }

    kubernetes_network_config {
      pods_cidr     = var.cluster_pods_cidr
      services_cidr = var.cluster_services_cidr
    }

    persistent_volume_config {
      freeform_tags = local.common_tags
    }

    service_lb_config {
      freeform_tags = local.common_tags
    }
  }

  lifecycle {
    ignore_changes = [name, freeform_tags, defined_tags]
  }
}

output "cluster_id" {
  value = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_endpoints" {
  value = one(oci_containerengine_cluster.oke_cluster.endpoints)
}

output "kubeconfig_command" {
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint ${var.cluster_endpoint_is_public ? "PUBLIC_ENDPOINT" : "PRIVATE_ENDPOINT"}"
}
