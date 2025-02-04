resource "aws_iam_role" "managed_ng" {
  name                  = "${var.context.eks_cluster_id}-${local.managed_node_group["node_group_name"]}"
  assume_role_policy    = data.aws_iam_policy_document.managed_ng_assume_role_policy.json
  path                  = var.path
  force_detach_policies = true
  tags                  = var.context.tags
}

resource "aws_iam_instance_profile" "managed_ng" {
  name = "${var.context.eks_cluster_id}-${local.managed_node_group["node_group_name"]}"
  role = aws_iam_role.managed_ng.name

  path = var.path
  tags = var.context.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "managed_ng_AmazonEKSWorkerNodePolicy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_ng.name
}

resource "aws_iam_role_policy_attachment" "managed_ng_AmazonEKS_CNI_Policy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_ng.name
}

resource "aws_iam_role_policy_attachment" "managed_ng_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_ng.name
}

resource "aws_iam_role_policy_attachment" "managed_ng_AmazonSSMManagedInstanceCore" {
  policy_arn = "${local.policy_arn_prefix}/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.managed_ng.name
}

resource "aws_iam_role_policy_attachment" "managed_ng" {
  for_each   = local.eks_worker_policies
  policy_arn = each.key
  role       = aws_iam_role.managed_ng.name
}
