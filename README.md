# Distributed Batch-Scoring Service 🏎️💨

A GPU-aware, cost-efficient batch-scoring backend for large-language models.

## Why?

Instant, serverless-style throughput for **T5-Large** (or any Hugging Face model) without sky-high GPU bills. **vLLM** paged-attention keeps VRAM low, while **Karpenter** spins up Spot GPUs only when the queue backs up.


## Architecture 🏗️

```
flowchart TD
    subgraph AWS
      VPC -->|private subnets| EKS
      EKS -->|CRD| Karpenter((Karpenter))
      EKS -->|Helm| RayServe[(Ray Serve + vLLM)]
      RayServe -->|REST| Clients
      RayServe -->|Redis| RAGCache[Redis Cluster]
      Monitor[Grafana + Prometheus] --> RayServe
      AutoScale[HPA]
      AutoScale --> RayServe
    end
    Terraform -->|IaC| AWS

```

## Prerequisites 🧰

| Tool | Version | Purpose | 
 | ----- | ----- | ----- | 
| **Terraform** | ≥ 1.6 | Provision AWS infra | 
| **AWS CLI** | ≥ 2.11 | Auth & ECR pushes | 
| **kubectl / Helm** | ≥ 3.13 | Workload deployments | 
| **Docker** | 25.x | Build & push images | 
| **GPU quota** | g5.\* x2 (vLLM likes VRAM) | Spot or On-Demand | 

Make sure you have an **AWS account** with permissions for EKS, IAM, VPC, ECR, CloudWatch, DynamoDB, and S3.

## Quick Start ⚡

**1. Clone & bootstrap**

```
$git clone [https://github.com/your-org/distributed-batch-scoring.git$](https://github.com/your-org/distributed-batch-scoring.git$) cd distributed-batch-scoring

```

**2. Provision EKS (≈15 min)**

```
$ cd terraform
$terraform init -backend-config=backend.hcl$ terraform apply -auto-approve

```

**3. Build & push the model image**

```
$ ../scripts/build_push.sh v0.1.0   # tag = version

```

**4. Deploy Ray Serve**

```
$ helm upgrade --install ray-serve ../helm/ray-serve \
    -n serve --create-namespace \
    --set image.repository="$ECR_REGISTRY/batch-scorer" \
    --set image.tag=v0.1.0

```

**5. Invoke the endpoint**

```
$kubectl port-forward svc/ray-serve 8000 -n serve &$ curl localhost:8000/generate -X POST \
       -H 'Content-Type: application/json' \
       -d '{"prompts":["Translate to French: Good morning!"]}'

```

**Tip:** Once you push a GitHub release `v0.1.0`, the CD workflow will rebuild the image and run the Helm upgrade for you.

## How It Works ⚙️

* **Ray Serve** deployment wraps **vLLM** so each replica carries a full model with paged-attention (squeezes memory).

* A custom metric—**incoming request count**—feeds the **HPA** to scale replicas from 1 to 10.

* **Karpenter** reacts to unschedulable Pods by launching Spot **g5 instances** (GPU). A warm pool keeps one node idle, resulting in a cold-start time of less than 2 minutes.

* **Prometheus** scrapes Ray metrics; the dashboard JSON lives in `/grafana/` (import via ID **18641**).

## Cost Optimisation 💰

* **Spot-only GPU NodePool** (override with `karpenter.tf`).

* **Warm-Pool TTL** of 300 seconds keeps latency SLO ≤ 1.5× while still saving \~47% vs. On-Demand.

* **Queue-depth HPA threshold** (`values.yaml`) is tuned at 8 req/s to hit \~70% GPU utilization.

## Operational Guides 📒

| Task | Command | 
 | ----- | ----- | 
| **Tail Ray logs** | `kubectl logs deploy/ray-serve -f -n serve` | 
| **Open Grafana URL** | `kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring` | 
| **Rotate model weights** | `helm upgrade ray-serve … --set modelName=google/flan-t5-xl` | 
| **Drain Spot node** | `kubectl cordon <node>; kubectl drain <node> --ignore-daemonsets` | 

## Contributing 🤝

* Fork → branch → PR.

* Run `make precommit` (runs `terraform fmt`, `helm lint`, and `ruff`).

* Ensure CI is green before requesting a review.

* Please open an issue for feature ideas or bug reports!

## License 📄

Distributed under the **Apache 2.0 License**. See `LICENSE` for details.
