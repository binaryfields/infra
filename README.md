# infrastructure

## Load Balancers

```yaml
apiVersion: v1
kind: Service
metadata:
    name: my-service
    annotations:
        oci.oraclecloud.com/load-balancer-type: "lb"
        service.beta.kubernetes.io/oci-load-balancer-security-list-management-mode: "None"
        service.beta.kubernetes.io/oci-load-balancer-subnet1: "<subnet-ocid>"
        service.beta.kubernetes.io/oci-load-balancer-subnet2: "<subnet-ocid>"
        service.beta.kubernetes.io/oci-load-balancer-security-rule-management-mode: "NSG"
        service.beta.kubernetes.io/oci-load-balancer-network-security-groups: "<nsg-ocid>"
spec:
    type: LoadBalancer
    # ... rest of service spec
```

## Reference

- https://www.oracle.com/webfolder/technetwork/tutorials/obe/oci/oke-full/index.html
- https://docs.public.content.oci.oraclecloud.com/en-us/iaas/Content/dev/terraform/tutorials/tf-simple-infrastructure.htm

- kms_key_id = var.kms_key_id # Add this variable
