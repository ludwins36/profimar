"""
Almacén en memoria (anillo) de request logs para la UI privada.
"""
from __future__ import annotations

import threading
import uuid
from collections import deque
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from typing import Any, Optional


@dataclass
class RequestLogEntry:
    id: str
    ts: str
    method: str
    path: str
    query: str
    client_ip: Optional[str]
    status_code: int
    duration_ms: float
    request_headers: dict[str, str] = field(default_factory=dict)
    request_body: Optional[str] = None
    response_body: Optional[str] = None
    error: Optional[str] = None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class RequestLogStore:
    """Buffer circular thread-safe de logs de request."""

    def __init__(self, max_entries: int = 500) -> None:
        self._max = max(50, max_entries)
        self._entries: deque[RequestLogEntry] = deque(maxlen=self._max)
        self._lock = threading.Lock()

    def resize(self, max_entries: int) -> None:
        max_entries = max(50, max_entries)
        with self._lock:
            if max_entries == self._max:
                return
            old = list(self._entries)
            self._max = max_entries
            self._entries = deque(old[-max_entries:], maxlen=max_entries)

    def add(self, entry: RequestLogEntry) -> None:
        with self._lock:
            self._entries.appendleft(entry)

    def clear(self) -> int:
        with self._lock:
            n = len(self._entries)
            self._entries.clear()
            return n

    def list(
        self,
        *,
        limit: int = 100,
        method: Optional[str] = None,
        path_contains: Optional[str] = None,
        status_min: Optional[int] = None,
        status_max: Optional[int] = None,
    ) -> list[dict[str, Any]]:
        with self._lock:
            items = list(self._entries)
        out: list[dict[str, Any]] = []
        method_u = method.upper().strip() if method else None
        path_f = path_contains.strip().lower() if path_contains else None
        for e in items:
            if method_u and e.method.upper() != method_u:
                continue
            if path_f and path_f not in e.path.lower():
                continue
            if status_min is not None and e.status_code < status_min:
                continue
            if status_max is not None and e.status_code > status_max:
                continue
            out.append(e.to_dict())
            if len(out) >= limit:
                break
        return out

    def get(self, entry_id: str) -> Optional[dict[str, Any]]:
        with self._lock:
            for e in self._entries:
                if e.id == entry_id:
                    return e.to_dict()
        return None

    def stats(self) -> dict[str, Any]:
        with self._lock:
            total = len(self._entries)
            by_status: dict[str, int] = {}
            for e in self._entries:
                key = f"{e.status_code // 100}xx"
                by_status[key] = by_status.get(key, 0) + 1
        return {"total": total, "max_entries": self._max, "by_status": by_status}


def new_entry_id() -> str:
    return uuid.uuid4().hex[:12]


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


# Singleton; main lo redimensiona según settings al arrancar
request_log_store = RequestLogStore()
