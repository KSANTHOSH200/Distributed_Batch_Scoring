# Create IAM role for Karpenter
resource "aws_iam_role" "karpenter" {
  name = "karpenter-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_trust.json
}

data "aws_iam_policy_document" "karpenter_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Helm‑install Karpenter controller
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter"
  version          = "v0.36.2"
  namespace        = "karpenter"
  create_namespace = true

  set {
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = aws_iam_role.karpenter.arn
  }
}

# GPU Spot NodePool with warm pools
data "aws_ssm_parameter" "g5_ami" {
  name = "/aws/service/ami-amazon-linux-latest/AL2023-AMI-Kernel-6.1-x86_64-GPU"
}

resource "kubernetes_manifest" "gpu_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata   = { name = "gpu-spot" }
    spec = {
      template = {
        spec = {
          nodeClassRef = { name = "gpu-class" }
          requirements = [
            { key = "node.kubernetes.io/instance-type", operator = "In", values = ["g5.2xlarge", "g5.4xlarge"] },
            { key = "karpenter.sh/capacity-type",      operator = "In", values = ["spot"] },
          ]
          taints = [{ key = "nvidia.com/gpu", value = "present", effect = "NoSchedule" }]
        }
      }
      disruption = { expireAfter = "72h" }
      limits     = { cpu = "1000", memory = "4000Gi" }
      warmPool   = { minSize = 1 }
    }
  }
}