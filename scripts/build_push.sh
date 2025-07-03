#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tag>"; exit 1
fi
TAG=$1
ECR_REGISTRY=${ECR_REGISTRY:-"$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${AWS_REGION:-us-east-1}.amazonaws.com"}
REPO="$ECR_REGISTRY/batch-scorer"

echo "Building $REPO:$TAG …"
docker build -t "$REPO:$TAG" app/
aws ecr describe-repositories --repository-names batch-scorer || aws ecr create-repository --repository-name batch-scorer
aws ecr get-login-password | docker login --username AWS --password-stdin "$ECR_REGISTRY"
docker push "$REPO:$TAG"