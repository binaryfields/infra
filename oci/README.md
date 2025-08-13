# OCI OKE Terraform Configuration

This Terraform configuration creates a production-ready OKE cluster on Oracle Cloud Infrastructure (OCI) with enhanced security, high availability, and best practices.

## Features

- **High Availability**: Multi-availability domain deployment
- **Enhanced Security**: Network Security Groups (NSGs), least privilege access, encryption
- **Cost Optimized**: Uses Always Free ARM instances (VM.Standard.A1.Flex)
- **Production Ready**: Service gateway, proper networking, comprehensive monitoring
- **Scalable**: Configurable node pools with auto-scaling capabilities
- **Modern Architecture**: Flannel CNI, image policy enforcement, encrypted volumes

## Architecture

The configuration creates:

- **VCN (Virtual Cloud Network)** with configurable CIDR (default: 10.0.0.0/16)
- **Multiple Availability Domains** for high availability
- **Public Subnets** across ADs for load balancers (10.0.1.0/24, 10.0.2.0/24, etc.)
- **Private Subnets** across ADs for worker nodes (10.0.11.0/24, 10.0.12.0/24, etc.)
- **Admin Subnet** for cluster endpoint (10.0.10.0/24)
- **Internet Gateway** for public internet access
- **NAT Gateway** for private subnet outbound access
- **Service Gateway** for OCI services access
- **Network Security Groups** for fine-grained security control
- **OKE Cluster** with Flannel CNI and configurable Kubernetes version
- **Node Pool** with ARM instances and flexible configuration

## Resources

- [https://github.com/oracle-terraform-modules/terraform-oci-oke]
- [https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#vcnconfig]
