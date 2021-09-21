/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#---------------------------------------------------------#
# EKS CLUSTER CORE VARIABLES
#---------------------------------------------------------#
#Following fields used in tagging resources and building the name of the cluster
#e.g., eks cluster name will be {tenant}-{environment}-{zone}-{resource}
#---------------------------------------------------------#
org               = "aws"     # Organization Name. Used to tag resources
tenant            = "aws001"  # AWS account name or unique id for tenant
environment       = "preprod" # Environment area eg., preprod or prod
zone              = "dev"     # Environment with in one sub_tenant or business unit
terraform_version = "Terraform v1.0.1"
#---------------------------------------------------------#
# VPC and PRIVATE SUBNET DETAILS for EKS Cluster
#---------------------------------------------------------#
#This provides two options Option1 and Option2. You should choose either of one to provide VPC details to the EKS cluster
#Option1: Creates a new VPC, private Subnets and VPC Endpoints by taking the inputs of vpc_cidr_block and private_subnets_cidr. VPC Endpoints are S3, SSM , EC2, ECR API, ECR DKR, KMS, CloudWatch Logs, STS, Elastic Load Balancing, Autoscaling
#Option2: Provide an existing vpc_id and private_subnet_ids

#---------------------------------------------------------#
# OPTION 1
#---------------------------------------------------------#
create_vpc             = true
enable_private_subnets = true
enable_public_subnets  = true

# Enable or Disable NAT Gateway and Internet Gateway for Public Subnets
enable_nat_gateway = true
single_nat_gateway = true
create_igw         = true

vpc_cidr_block       = "10.1.0.0/18"
private_subnets_cidr = ["10.1.0.0/22", "10.1.4.0/22", "10.1.8.0/22"]
public_subnets_cidr  = ["10.1.12.0/22", "10.1.16.0/22", "10.1.20.0/22"]

# Change this to true when you want to create VPC endpoints for Private subnets
create_vpc_endpoints = true
#---------------------------------------------------------#
# OPTION 2
#---------------------------------------------------------#
# create_vpc = false
# vpc_id = "xxxxxx"
# private_subnet_ids = ['xxxxxx','xxxxxx','xxxxxx']
# public_subnet_ids = ['xxxxxx','xxxxxx','xxxxxx']

#---------------------------------------------------------#
# EKS CONTROL PLANE VARIABLES
# API server endpoint access options
#   Endpoint public access: true    - Your cluster API server is accessible from the internet. You can, optionally, limit the CIDR blocks that can access the public endpoint.
#   Endpoint private access: true   - Kubernetes API requests within your cluster's VPC (such as node to control plane communication) use the private VPC endpoint.
#---------------------------------------------------------#
create_eks              = true
kubernetes_version      = "1.20"
endpoint_private_access = true
endpoint_public_access  = true

# Enable IAM Roles for Service Accounts (IRSA) on the EKS cluster
enable_irsa = true

enabled_cluster_log_types    = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cluster_log_retention_period = 7

enable_vpc_cni_addon  = true
vpc_cni_addon_version = "v1.8.0-eksbuild.1"

enable_coredns_addon  = true
coredns_addon_version = "v1.8.3-eksbuild.1"

enable_kube_proxy_addon  = true
kube_proxy_addon_version = "v1.20.4-eksbuild.2"

#---------------------------------------------------------#
# EKS SELF MANAGED WORKER NODE GROUPS
# Define Node groups as map of maps object as shown below. Each node group creates the following
#    1. New node group (Linux/Bottlerocket/Windows)
#    2. IAM role and policies for Node group
#    3. Security Group for Node group
#    4. Launch Templates for Node group
#    5. Autoscaling Group
#---------------------------------------------------------#
enable_self_managed_nodegroups = true
# Enable Windows Support
enable_windows_support = true
self_managed_node_groups = {
  #---------------------------------------------------------#
  # ON-DEMAND Self Managed Windows Worker Node Group
  #---------------------------------------------------------#
  windows_ondemand = {
    node_group_name = "windows-ondemand" # Name is used to create a dedicated IAM role for each node group and adds to AWS-AUTH config map
    custom_ami_type = "windows"          # amazonlinux2eks  or bottlerocket or windows
    # custom_ami_id   = "ami-xxxxxxxxxxxxxxxx" # Bring your own custom AMI. Default Windows AMI is the latest EKS Optimized Windows Server 2019 English Core AMI.
    public_ip = false # Enable only for public subnets

    disk_size     = 50
    instance_type = "m5.large"

    desired_size = 2
    max_size     = 4
    min_size     = 2

    k8s_labels = {
      Environment = "preprod"
      Zone        = "dev"
      WorkerType  = "WINDOWS_ON_DEMAND"
    }

    additional_tags = {
      ExtraTag    = "windows-on-demand"
      Name        = "windows-on-demand"
      subnet_type = "private"
    }

    subnet_type = "private" # private or public
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']

    create_worker_security_group = false # Creates a dedicated sec group for this Node Group
  }
}
#---------------------------------------------------------#
# EKS MANAGED WORKER NODE GROUPS
# Define Node groups as map of maps object as shown below. Each node group creates the following
#    1. New node group (Linux/Bottlerocket)
#    2. IAM role and policies for Node group
#    3. Security Group for Node group (Optional)
#    4. Launch Templates for Node group   (Optional)
#---------------------------------------------------------#
enable_managed_nodegroups = true
managed_node_groups = {
  #---------------------------------------------------------#
  # SPOT Worker Group - Worker Group - 1
  #---------------------------------------------------------#
  spot_m5 = {
    # 1> Node Group configuration - Part1
    node_group_name        = "managed-spot-m5"
    create_launch_template = true              # false will use the default launch template
    custom_ami_type        = "amazonlinux2eks" # amazonlinux2eks  or bottlerocket
    public_ip              = false             # Use this to enable public IP for EC2 instances; only for public subnets used in launch templates ;
    pre_userdata           = <<-EOT
               yum install -y amazon-ssm-agent
               systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent"
           EOT

    # Node Group scaling configuration
    desired_size = 3
    max_size     = 3
    min_size     = 3

    # Node Group update configuration. Set the maximum number or percentage of unavailable nodes to be tolerated during the node group version update.
    max_unavailable = 1 # or percentage = 20

    # Node Group compute configuration
    ami_type       = "AL2_x86_64"
    capacity_type  = "SPOT"
    instance_types = ["t3.medium", "t3a.medium"]
    disk_size      = 50

    # Node Group network configuration
    subnet_type = "private" # private or public
    subnet_ids  = []        # Define your private/public subnets list with comma seprated subnet_ids  = ['subnet1','subnet2','subnet3']

    k8s_taints = []

    k8s_labels = {
      Environment = "preprod"
      Zone        = "dev"
      WorkerType  = "SPOT"
    }
    additional_tags = {
      ExtraTag    = "spot_nodes"
      Name        = "spot"
      subnet_type = "private"
    }

    create_worker_security_group = false
  }
}

#---------------------------------------------------------#
# ENABLE HELM MODULES
# Please note that you may need to download the docker images for each
#          helm module and push it to ECR if you create fully private EKS Clusters with no access to internet to fetch docker images.
#          README with instructions available in each HELM module under helm/
#---------------------------------------------------------#
# Enable this if worker Node groups has access to internet to download the docker images
# Or Make it false and set the private contianer image repo url in source/eks.tf; currently this defaults to ECR
public_docker_repo = true

#---------------------------------------------------------#
# ENABLE METRICS SERVER
#---------------------------------------------------------#
metrics_server_enable = true
#---------------------------------------------------------#
# ENABLE CLUSTER AUTOSCALER
#---------------------------------------------------------#
cluster_autoscaler_enable = true

#---------------------------------------------------------//
# ENABLE AWS LB INGRESS CONTROLLER
#---------------------------------------------------------//
lb_ingress_controller_enable = true