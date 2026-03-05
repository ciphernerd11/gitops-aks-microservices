"""
Alert API — FastAPI service for ingesting and broadcasting emergency alerts.
Connects to Redis for caching active alerts (gracefully degrades if Redis is unavailable).
"""

import os
import json
import uuid
from datetime import datetime, timezone
from typing import Optional
from contextlib import suppress

from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ── Configuration ──
REDIS_HOST = os.getenv("REDIS_HOST", "redis-service")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_DB = int(os.getenv("REDIS_DB", "0"))
CACHE_TTL = int(os.getenv("CACHE_TTL", "300"))  # seconds

app = FastAPI(
    title="Disaster Relief Alert API",
    version="1.0.0",
    description="Ingest, cache, and broadcast emergency alerts.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Redis (optional — degrades gracefully) ──
_redis_available = True
_redis_client = None


def _get_redis():
    """Return a Redis client or None if unavailable."""
    global _redis_available, _redis_client

    if not _redis_available:
        return None

    if _redis_client is None:
        try:
            import redis
            _redis_client = redis.Redis(
                host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB,
                decode_responses=True,
                socket_connect_timeout=1, socket_timeout=1,
            )
            _redis_client.ping()  # test connectivity
        except Exception:
            _redis_available = False
            _redis_client = None
            return None

    return _redis_client


def _redis_get(key: str) -> Optional[str]:
    r = _get_redis()
    if r is None:
        return None
    try:
        return r.get(key)
    except Exception:
        return None


def _redis_delete(key: str):
    r = _get_redis()
    if r is None:
        return
    with suppress(Exception):
        r.delete(key)


def _redis_setex(key: str, ttl: int, value: str):
    r = _get_redis()
    if r is None:
        return
    with suppress(Exception):
        r.setex(key, ttl, value)


# ── Models ──
class AlertCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=256)
    severity: str = Field(..., pattern="^(critical|high|medium|low)$")
    location: str = Field(..., min_length=1, max_length=256)
    description: str = Field(default="", max_length=2048)


class Alert(AlertCreate):
    id: str
    created_at: str


# ── In-memory store (production would use a database) ──
alerts_store: list[dict] = []

CACHE_KEY = "active_alerts"


# ── Routes ──
@app.get("/health", tags=["ops"])
async def health():
    return {"status": "ok", "service": "alert-api"}


@app.post("/alerts", response_model=Alert, status_code=status.HTTP_201_CREATED, tags=["alerts"])
async def create_alert(payload: AlertCreate):
    alert = {
        "id": str(uuid.uuid4()),
        "created_at": datetime.now(timezone.utc).isoformat(),
        **payload.model_dump(),
    }
    alerts_store.append(alert)
    _redis_delete(CACHE_KEY)
    return alert


@app.get("/alerts", tags=["alerts"])
async def list_alerts():
    # Try cache first
    cached = _redis_get(CACHE_KEY)
    if cached:
        return json.loads(cached)

    # Build response
    data = sorted(alerts_store, key=lambda a: a["created_at"], reverse=True)

    # Populate cache
    _redis_setex(CACHE_KEY, CACHE_TTL, json.dumps(data))

    return data
