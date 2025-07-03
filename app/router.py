from ray import serve
from typing import Dict

@serve.deployment(route_prefix="/score")
class ModelRouter:
    def __init__(self, model_handles: Dict[str, serve.DeploymentHandle]):
        self.model_handles = model_handles

    async def __call__(self, request):
        model = request.query_params.get("model", "t5")
        return await self.model_handles[model].remote(request)