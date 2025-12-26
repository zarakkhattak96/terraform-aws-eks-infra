# Terraform AWS EKS Infrastructure

A production-ready Infrastructure-as-Code (IaC) repository for provisioning a complete AWS EKS (Elastic Kubernetes Service) infrastructure using Terraform. This repository demonstrates best practices for modular Terraform code, remote state management, and Kubernetes deployment.

## 🏗️ Architecture

This repository provisions the following AWS infrastructure:

### Network Layer
- **VPC**: Custom CIDR block with DNS support
- **Public Subnets**: Multiple availability zones with Internet Gateway access
- **Private Subnets**: Multiple availability zones with NAT Gateway for outbound internet access
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: For private subnet outbound internet access (one per availability zone)
- **Route Tables**: Separate routing for public and private subnets

### Security Layer
- **Security Groups**: 
  - EKS Cluster Security Group (allows HTTPS from VPC)
  - EKS Node Group Security Group (allows traffic from cluster and nodes)

### IAM Layer
- **EKS Cluster Role**: IAM role with required policies for EKS cluster
- **EKS Node Group Role**: IAM role with required policies for worker nodes

### Compute Layer
- **EKS Cluster**: Managed Kubernetes control plane
- **EKS Node Group**: Managed worker nodes with auto-scaling capabilities
- **CloudWatch Logs**: Cluster logging enabled

## 📁 Repository Structure

```
terraform-aws-eks-infra/
├── modules/
│   ├── vpc/                 # VPC, subnets, IGW, NAT Gateways
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/     # Security groups for EKS
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                 # IAM roles for EKS
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/                 # EKS cluster and node groups
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── k8s-manifests/           # Sample Kubernetes deployments
│   ├── nginx-deployment.yaml
│   ├── nginx-service.yaml
│   └── README.md
├── main.tf                  # Main Terraform configuration
├── variables.tf             # Input variables
├── outputs.tf               # Output values
├── backend.tf.example       # Example backend configuration
├── terraform.tfvars.example # Example variables file
├── .gitignore
└── README.md
```

## 🚀 Prerequisites

Before using this repository, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
   ```bash
   aws configure
   ```
3. **Terraform** (>= 1.0) installed
   ```bash
   terraform version
   ```
4. **kubectl** installed (for deploying sample app)
   ```bash
   kubectl version --client
   ```

### Required AWS Permissions

Your AWS credentials need permissions to create:
- VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
- Security Groups
- IAM Roles and Policies
- EKS Clusters and Node Groups
- CloudWatch Log Groups
- EC2 Instances (for node groups)

## 📋 Quick Start

### 1. Clone and Configure

```bash
git clone <repository-url>
cd terraform-aws-eks-infra
```

### 2. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired configuration:

```hcl
aws_region = "us-east-1"
project_name = "my-eks-cluster"
vpc_cidr = "10.0.0.0/16"
# ... other variables
```

### 3. (Optional) Configure Remote Backend

For production use, configure S3 + DynamoDB backend:

1. Create S3 bucket for state:
   ```bash
   aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1
   aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
   aws s3api put-bucket-encryption --bucket your-terraform-state-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
   ```

2. Create DynamoDB table for locking:
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

3. Copy and configure backend:
   ```bash
   cp backend.tf.example backend.tf
   # Edit backend.tf with your bucket and table names
   ```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan
```

This will show you what resources will be created. Review carefully.

### 6. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will take approximately 15-20 minutes to complete.

### 7. Configure kubectl

After the cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region <your-region> --name <cluster-name>
```

Or use the output command:

```bash
terraform output -raw kubeconfig_command | bash
```

Verify access:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### 8. Deploy Sample Application

Deploy the sample nginx application to verify the cluster:

```bash
kubectl apply -f k8s-manifests/nginx-deployment.yaml
kubectl apply -f k8s-manifests/nginx-service.yaml
```

Check the deployment:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

Get the LoadBalancer URL (may take a few minutes):

```bash
kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Test the application:

```bash
curl http://$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## 🔧 Terraform Commands

### Initialize
```bash
terraform init
```
Initializes the Terraform working directory and downloads required providers.

### Plan
```bash
terraform plan
```
Creates an execution plan showing what will be created, modified, or destroyed.

### Apply
```bash
terraform apply
```
Applies the changes to create or update infrastructure.

### Destroy
```bash
terraform destroy
```
⚠️ **Warning**: This will destroy all resources. Make sure you want to delete everything.

### Outputs
```bash
terraform output
```
Shows all output values.

```bash
terraform output eks_cluster_endpoint
```
Shows a specific output value.

### Format
```bash
terraform fmt
```
Formats Terraform files according to style conventions.

### Validate
```bash
terraform validate
```
Validates the Terraform configuration files.

## 📊 Key Outputs

After applying, you'll get the following outputs:

- `vpc_id`: VPC ID
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs
- `eks_cluster_id`: EKS cluster ID
- `eks_cluster_arn`: EKS cluster ARN
- `eks_cluster_name`: EKS cluster name
- `eks_cluster_endpoint`: EKS API server endpoint
- `eks_cluster_version`: Kubernetes version
- `kubeconfig_command`: Command to update kubeconfig

View all outputs:

```bash
terraform output
```

## 🔐 Security Considerations

1. **Private Subnets**: EKS nodes are deployed in private subnets for security
2. **Security Groups**: Restrictive security group rules following least privilege
3. **IAM Roles**: Separate roles for cluster and nodes with minimal required permissions
4. **Encryption**: Backend state encryption enabled (if using S3 backend)
5. **Network Isolation**: Private subnets with NAT Gateway for controlled outbound access

## 💰 Cost Optimization

- **NAT Gateways**: Consider using fewer NAT Gateways (one per AZ) or shared NAT Gateway
- **Node Instance Types**: Use smaller instance types for development (t3.small, t3.medium)
- **SPOT Instances**: Use `node_capacity_type = "SPOT"` for cost savings (with appropriate node group settings)
- **Auto-scaling**: Configure appropriate min/max/desired sizes based on workload

## 🛠️ Customization

### Adjust Node Group Size

Edit `terraform.tfvars`:

```hcl
node_group_desired_size = 3
node_group_max_size     = 6
node_group_min_size     = 2
```

### Change Instance Types

```hcl
node_instance_types = ["t3.large"]
```

### Use SPOT Instances

```hcl
node_capacity_type = "SPOT"
```

### Enable SSM Access

```hcl
enable_ssm_access = true
```

## 🧹 Cleanup

To destroy all resources:

```bash
# First, delete Kubernetes resources
kubectl delete -f k8s-manifests/

# Then destroy Terraform infrastructure
terraform destroy
```

## 📝 Module Details

### VPC Module
- Creates VPC with DNS support
- Public and private subnets across multiple AZs
- Internet Gateway for public subnets
- NAT Gateways for private subnet outbound access
- Route tables and associations

### Security Groups Module
- EKS cluster security group (HTTPS from VPC)
- EKS node group security group (cluster and node communication)

### IAM Module
- EKS cluster role with required policies
- EKS node group role with required policies
- Optional SSM access for debugging

### EKS Module
- EKS cluster with configurable Kubernetes version
- Managed node group with auto-scaling
- CloudWatch logging
- Configurable instance types and capacity

## 🐛 Troubleshooting

### kubectl Connection Issues

If you can't connect to the cluster:

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Check cluster status
aws eks describe-cluster --name <cluster-name> --region <region>
```

### Node Group Not Joining

Check node group status:

```bash
aws eks describe-nodegroup --cluster-name <cluster-name> --nodegroup-name <nodegroup-name> --region <region>
```

Check CloudWatch logs for issues.

### Pods Not Starting

Check node resources:

```bash
kubectl describe nodes
kubectl get events --all-namespaces
```

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 📄 License

This project is provided as-is for educational and portfolio purposes.

## 🤝 Contributing

This is a portfolio project demonstrating Infrastructure-as-Code skills. Feel free to fork and customize for your needs.

---

**Note**: This infrastructure will incur AWS costs. Monitor your usage and destroy resources when not in use.
