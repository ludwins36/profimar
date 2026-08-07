"""
Middleware que registra requests HTTP cuando LOG_REQUESTS=true.
"""
from __future__ import annotations

import json
import time
from typing import Callable, Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.core.config import get_settings
from app.core.request_log_store import RequestLogEntry, new_entry_id, request_log_store, utc_now_iso

# Rutas que no se registran (evita ruido y recursión en la UI de logs)
_SKIP_PREFIXES = (
    "/private/logs",
    "/docs",
    "/redoc",
    "/openapi.json",
    "/favicon.ico",
)

_SENSITIVE_HEADERS = frozenset({
    "authorization",
    "cookie",
    "set-cookie",
    "x-logs-token",
    "x-api-key",
})

_MAX_BODY_CHARS = 32_000


def _should_skip(path: str) -> bool:
    return any(path == p or path.startswith(p + "/") for p in _SKIP_PREFIXES)


def _client_ip(request: Request) -> Optional[str]:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    if request.client:
        return request.client.host
    return None


def _safe_headers(request: Request) -> dict[str, str]:
    out: dict[str, str] = {}
    for k, v in request.headers.items():
        lk = k.lower()
        if lk in _SENSITIVE_HEADERS:
            out[k] = "***"
        else:
            out[k] = v
    return out


def _truncate(text: Optional[str], max_chars: int = _MAX_BODY_CHARS) -> Optional[str]:
    if text is None:
        return None
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + f"\n… [truncated {len(text) - max_chars} chars]"


def _decode_body(raw: bytes, content_type: str) -> Optional[str]:
    if not raw:
        return None
    ct = (content_type or "").lower()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return f"<binary {len(raw)} bytes>"
    if "json" in ct:
        try:
            return json.dumps(json.loads(text), ensure_ascii=False, indent=2)
        except Exception:
            return text
    return text


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        settings = get_settings()
        if not settings.log_requests or _should_skip(request.url.path):
            return await call_next(request)

        body_bytes = await request.body()

        async def receive() -> dict:
            return {"type": "http.request", "body": body_bytes, "more_body": False}

        request = Request(request.scope, receive)

        started = time.perf_counter()
        status_code = 500
        error: Optional[str] = None

        try:
            response = await call_next(request)
            status_code = response.status_code

            resp_chunks: list[bytes] = []
            async for chunk in response.body_iterator:
                resp_chunks.append(chunk if isinstance(chunk, bytes) else chunk.encode("utf-8"))
            resp_raw = b"".join(resp_chunks)
            response_body_preview = _truncate(
                _decode_body(resp_raw, response.headers.get("content-type", ""))
            )

            new_response = Response(
                content=resp_raw,
                status_code=response.status_code,
                headers=dict(response.headers),
                media_type=response.media_type,
                background=response.background,
            )
            duration_ms = (time.perf_counter() - started) * 1000.0
            request_log_store.add(
                RequestLogEntry(
                    id=new_entry_id(),
                    ts=utc_now_iso(),
                    method=request.method,
                    path=request.url.path,
                    query=str(request.url.query or ""),
                    client_ip=_client_ip(request),
                    status_code=status_code,
                    duration_ms=round(duration_ms, 2),
                    request_headers=_safe_headers(request),
                    request_body=_truncate(
                        _decode_body(body_bytes, request.headers.get("content-type", ""))
                    ),
                    response_body=response_body_preview,
                    error=None,
                )
            )
            return new_response
        except Exception as e:
            error = str(e)
            duration_ms = (time.perf_counter() - started) * 1000.0
            request_log_store.add(
                RequestLogEntry(
                    id=new_entry_id(),
                    ts=utc_now_iso(),
                    method=request.method,
                    path=request.url.path,
                    query=str(request.url.query or ""),
                    client_ip=_client_ip(request),
                    status_code=status_code,
                    duration_ms=round(duration_ms, 2),
                    request_headers=_safe_headers(request),
                    request_body=_truncate(
                        _decode_body(body_bytes, request.headers.get("content-type", ""))
                    ),
                    response_body=None,
                    error=error,
                )
            )
            raise
