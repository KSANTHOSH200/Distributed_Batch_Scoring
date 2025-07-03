"""Simple Redis‑backed RAG cache."""
import hashlib, json, os
import redis

redis_host = os.getenv("REDIS_HOST", "redis")
redis_port = int(os.getenv("REDIS_PORT", 6379))
client = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)

TTL_SECONDS = 3600

def _key(prompt: str) -> str:
    return hashlib.sha256(prompt.encode()).hexdigest()

def get(prompt: str):
    return client.get(_key(prompt))

def set(prompt: str, result: str):
    client.setex(_key(prompt), TTL_SECONDS, json.dumps(result))