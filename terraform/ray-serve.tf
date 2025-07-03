# ECR repository to store application images
aresource "aws_ecr_repository" "app" {
  name               = "${var.project_name}-ray"
  image_scan_on_push = true
}

# Path to the local Helm chart
locals {
  chart_path = "${path.module}/../helm/ray-serve"
}

# Deploy Ray Serve via Helm
resource "helm_release" "ray_serve" {
  name             = "ray-serve"
  chart            = local.chart_path
  namespace        = "serve"
  create_namespace = true

  # Inject image coordinates into the values.yaml
  set {
    name  = "image.repository"
    value = aws_ecr_repository.app.repository_url
  }
  set {
    name  = "image.tag"
    value = var.image_tag
  }
  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  depends_on = [module.eks]
}