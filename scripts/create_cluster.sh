#!/usr/bin/env bash
set -euo pipefail

cd terraform
echo "Initializing Terraform …"
terraform init -backend-config=backend.hcl
terraform apply -auto-approve "$@"