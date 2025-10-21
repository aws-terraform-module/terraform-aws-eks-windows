## Issues:

### Add new subnet failed.

```plaintext
╷
│ Error: [WARN] A duplicate Security Group rule was found on (sg-057f013bc8b4bd2d9). This may be
│ a side effect of a now-fixed Terraform issue causing two security groups with
│ identical attributes but different source_security_group_ids to overwrite each
│ other in the state. See https://github.com/hashicorp/terraform/pull/2376 for more
│ information and instructions for recovery. Error: operation error EC2: AuthorizeSecurityGroupIngress, https response error StatusCode: 400, RequestID: 9ba628a1-8e5a-4d6b-9dff-9520f8ea4cd1, api error InvalidPermission.Duplicate: the specified rule "peer: 10.0.0.0/19, ALL, ALLOW" already exists
│ 
│   with module.eks-windows.module.eks.aws_security_group_rule.node["ingress_subnet_ids_all"],
│   on .terraform/modules/eks-windows.eks/node_groups.tf line 192, in resource "aws_security_group_rule" "node":
│  192: resource "aws_security_group_rule" "node" {
```

Please update the module to version **4.2.4**, delete the subnet that was announced in the error message, and retry running 'terraform apply.'
We updated the logic to avoid errors during the next provisioning when was using **EKS-Windows 4.2.4**.

 

### Error when overwriting the `amazon_vpc_cni` config map.

```plaintext
Plan: 3 to add, 1 to change, 2 to destroy.
╷
│ Error: Get "http://localhost/api/v1/namespaces/kube-system/configmaps/amazon-vpc-cni": dial tcp [::1]:80: connect: connection refused
│ 
│   with module.eks-windows.kubernetes_config_map_v1_data.amazon_vpc_cni[0],
│   on .terraform/modules/eks-windows/c4-cni.tf line 25, in resource "kubernetes_config_map_v1_data" "amazon_vpc_cni":
│   25: resource "kubernetes_config_map_v1_data" "amazon_vpc_cni" {
│ 
╵
2024-03-26T08:30:40.15121401Z stdout P 
```

refer to the link: [**\[Terraform\] Resolving aws-auth error when deleting EKS Cluster**](https://kim-dragon.tistory.com/262)

We need manually to delete `amazon_vpc_cni` from `tfstate` by the below command:

```plaintext
terraform state rm module.eks-windows.kubernetes_config_map_v1_data.amazon_vpc_cni
```

### Operation error EKS: CreateAccessEntry, https response error StatusCode: 409

refer to: [https://nimtechnology.com/2024/03/21/eks-operation-error-eks-createaccessentry-https-response-error-statuscode-409/](https://nimtechnology.com/2024/03/21/eks-operation-error-eks-createaccessentry-https-response-error-statuscode-409/)