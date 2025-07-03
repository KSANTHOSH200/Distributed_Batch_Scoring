import ray
from ray import serve
from vllm import LLM, SamplingParams

ray.init(address="auto", namespace="serve")

MODEL_NAME = "google/t5-large-ssm"

@serve.deployment(
    route_prefix="/generate",
    autoscaling_config={
        "min_replicas": 1,
        "max_replicas": 10,
        "metrics_interval_s": 5,
        "target_num_ongoing_requests_per_replica": 8,
    },
    ray_actor_options={"num_gpus": 1, "resources": {"nvidia.com/gpu": 1}},
)
class BatchScorer:
    def __init__(self):
        self.llm = LLM(MODEL_NAME, trust_remote_code=True,
                       max_num_seqs=64, tensor_parallel_size=1)
        self.params = SamplingParams(temperature=0.0, max_tokens=128)

    async def __call__(self, request):
        data = await request.json()
        prompts = data.get("prompts", [])
        res = self.llm.generate(prompts, self.params)
        return {"outputs": [r.outputs[0].text for r in res]}

app = serve.run(BatchScorer.bind())