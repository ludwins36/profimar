"""
UI privada e API JSON para consultar request logs.
Protegida con LOGS_SECRET (?token= o header X-Logs-Token).
"""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Header, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, JSONResponse

from app.core.config import get_settings
from app.core.request_log_store import request_log_store

router = APIRouter(prefix="/private/logs", tags=["Logs privados"])


def _require_token(
    token: Optional[str],
    x_logs_token: Optional[str],
) -> None:
    settings = get_settings()
    secret = (settings.logs_secret or "").strip()
    if not secret:
        raise HTTPException(
            status_code=503,
            detail="Configure LOGS_SECRET en .env para usar /private/logs",
        )
    provided = (token or x_logs_token or "").strip()
    if not provided or provided != secret:
        raise HTTPException(status_code=401, detail="Token inválido o ausente")


@router.get("", response_class=HTMLResponse)
async def logs_ui(
    request: Request,
    token: Optional[str] = Query(None, description="LOGS_SECRET"),
    x_logs_token: Optional[str] = Header(None, alias="X-Logs-Token"),
) -> HTMLResponse:
    """Interfaz interactiva de request logs."""
    _require_token(token, x_logs_token)
    settings = get_settings()
    # Token embebido solo en la página autenticada (misma pestaña)
    safe_token = (token or x_logs_token or "").replace("\\", "\\\\").replace("'", "\\'")
    html = _UI_HTML.replace("__TOKEN__", safe_token).replace(
        "__LOG_REQUESTS__",
        "true" if settings.log_requests else "false",
    ).replace("__APP__", settings.app_name)
    return HTMLResponse(html)


@router.get("/api")
async def logs_list(
    token: Optional[str] = Query(None),
    x_logs_token: Optional[str] = Header(None, alias="X-Logs-Token"),
    limit: int = Query(100, ge=1, le=500),
    method: Optional[str] = Query(None),
    path_contains: Optional[str] = Query(None),
    status_min: Optional[int] = Query(None),
    status_max: Optional[int] = Query(None),
) -> JSONResponse:
    _require_token(token, x_logs_token)
    settings = get_settings()
    items = request_log_store.list(
        limit=limit,
        method=method,
        path_contains=path_contains,
        status_min=status_min,
        status_max=status_max,
    )
    return JSONResponse(
        {
            "status": "ok",
            "logging_enabled": settings.log_requests,
            "stats": request_log_store.stats(),
            "items": items,
        }
    )


@router.get("/api/{entry_id}")
async def logs_detail(
    entry_id: str,
    token: Optional[str] = Query(None),
    x_logs_token: Optional[str] = Header(None, alias="X-Logs-Token"),
) -> JSONResponse:
    _require_token(token, x_logs_token)
    item = request_log_store.get(entry_id)
    if not item:
        raise HTTPException(status_code=404, detail="Log no encontrado")
    return JSONResponse({"status": "ok", "item": item})


@router.delete("/api")
async def logs_clear(
    token: Optional[str] = Query(None),
    x_logs_token: Optional[str] = Header(None, alias="X-Logs-Token"),
) -> JSONResponse:
    _require_token(token, x_logs_token)
    cleared = request_log_store.clear()
    return JSONResponse({"status": "ok", "cleared": cleared})


_UI_HTML = r"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>__APP__ · Request logs</title>
  <style>
    :root {
      --bg: #0f1419;
      --panel: #1a222c;
      --border: #2c3848;
      --text: #e7ecf2;
      --muted: #8b9aab;
      --accent: #3d9cf0;
      --ok: #3dbf7a;
      --warn: #e6a23c;
      --err: #e85d5d;
      --mono: "Cascadia Code", "Consolas", "SFMono-Regular", monospace;
      --sans: "Segoe UI", system-ui, sans-serif;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: var(--sans);
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
    }
    header {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      align-items: center;
      justify-content: space-between;
      padding: 16px 20px;
      border-bottom: 1px solid var(--border);
      background: var(--panel);
      position: sticky;
      top: 0;
      z-index: 10;
    }
    h1 { margin: 0; font-size: 1.1rem; font-weight: 600; }
    .badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 0.75rem;
      font-weight: 600;
    }
    .badge.on { background: #1e3d2f; color: var(--ok); }
    .badge.off { background: #3d2a1e; color: var(--warn); }
    .controls {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      align-items: center;
    }
    input, select, button {
      font: inherit;
      border-radius: 6px;
      border: 1px solid var(--border);
      background: var(--bg);
      color: var(--text);
      padding: 6px 10px;
    }
    button {
      cursor: pointer;
      background: #243040;
    }
    button:hover { border-color: var(--accent); }
    button.danger { color: var(--err); }
    main {
      display: grid;
      grid-template-columns: minmax(280px, 1fr) minmax(320px, 1.2fr);
      gap: 0;
      height: calc(100vh - 65px);
    }
    @media (max-width: 900px) {
      main { grid-template-columns: 1fr; height: auto; }
    }
    .list, .detail {
      overflow: auto;
      border-right: 1px solid var(--border);
      padding: 12px;
    }
    .detail { border-right: none; }
    .row {
      padding: 10px 12px;
      border: 1px solid var(--border);
      border-radius: 8px;
      margin-bottom: 8px;
      cursor: pointer;
      background: var(--panel);
    }
    .row:hover, .row.active { border-color: var(--accent); }
    .row .meta {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
      align-items: center;
      font-size: 0.85rem;
    }
    .method {
      font-family: var(--mono);
      font-weight: 700;
      font-size: 0.75rem;
      min-width: 3.2rem;
    }
    .path { font-family: var(--mono); font-size: 0.8rem; word-break: break-all; }
    .muted { color: var(--muted); font-size: 0.75rem; }
    .s2 { color: var(--ok); }
    .s3 { color: var(--accent); }
    .s4 { color: var(--warn); }
    .s5 { color: var(--err); }
    pre {
      margin: 0;
      padding: 12px;
      background: #0b0f14;
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow: auto;
      font-family: var(--mono);
      font-size: 0.78rem;
      white-space: pre-wrap;
      word-break: break-word;
      max-height: 40vh;
    }
    .section { margin-bottom: 16px; }
    .section h3 {
      margin: 0 0 8px;
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: var(--muted);
    }
    .empty { color: var(--muted); padding: 24px; text-align: center; }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>__APP__ · Request logs</h1>
      <span id="badge" class="badge off">logging off</span>
      <span id="stats" class="muted"></span>
    </div>
    <div class="controls">
      <select id="method">
        <option value="">METHOD</option>
        <option>GET</option>
        <option>POST</option>
        <option>PUT</option>
        <option>PATCH</option>
        <option>DELETE</option>
      </select>
      <input id="path" placeholder="path contains…" />
      <button type="button" id="refresh">Actualizar</button>
      <label class="muted"><input type="checkbox" id="auto" /> auto 3s</label>
      <button type="button" id="clear" class="danger">Limpiar</button>
    </div>
  </header>
  <main>
    <section class="list" id="list"><div class="empty">Cargando…</div></section>
    <section class="detail" id="detail"><div class="empty">Selecciona un request</div></section>
  </main>
  <script>
    const TOKEN = '__TOKEN__';
    const qs = (p) => {
      const u = new URL(p, location.origin);
      u.searchParams.set('token', TOKEN);
      return u.toString();
    };
    let items = [];
    let selectedId = null;
    let timer = null;

    function statusClass(code) {
      if (code >= 500) return 's5';
      if (code >= 400) return 's4';
      if (code >= 300) return 's3';
      return 's2';
    }

    function renderList() {
      const el = document.getElementById('list');
      if (!items.length) {
        el.innerHTML = '<div class="empty">Sin logs aún. Activa LOG_REQUESTS=true y llama una API.</div>';
        return;
      }
      el.innerHTML = items.map(it => `
        <div class="row ${it.id === selectedId ? 'active' : ''}" data-id="${it.id}">
          <div class="meta">
            <span class="method">${it.method}</span>
            <span class="${statusClass(it.status_code)}">${it.status_code}</span>
            <span class="muted">${it.duration_ms} ms</span>
            <span class="muted">${it.ts}</span>
          </div>
          <div class="path">${it.path}${it.query ? '?' + it.query : ''}</div>
          <div class="muted">${it.client_ip || ''}${it.error ? ' · ERROR' : ''}</div>
        </div>
      `).join('');
      el.querySelectorAll('.row').forEach(row => {
        row.addEventListener('click', () => {
          selectedId = row.dataset.id;
          renderList();
          renderDetail(items.find(x => x.id === selectedId));
        });
      });
    }

    function renderDetail(it) {
      const el = document.getElementById('detail');
      if (!it) {
        el.innerHTML = '<div class="empty">Selecciona un request</div>';
        return;
      }
      el.innerHTML = `
        <div class="section">
          <h3>Resumen</h3>
          <div class="meta">
            <span class="method">${it.method}</span>
            <span class="${statusClass(it.status_code)}">${it.status_code}</span>
            <span class="muted">${it.duration_ms} ms · ${it.ts}</span>
          </div>
          <div class="path" style="margin-top:8px">${it.path}${it.query ? '?' + it.query : ''}</div>
          <div class="muted">IP: ${it.client_ip || '—'} · id: ${it.id}</div>
          ${it.error ? `<pre style="color:var(--err);margin-top:8px">${escapeHtml(it.error)}</pre>` : ''}
        </div>
        <div class="section">
          <h3>Request body</h3>
          <pre>${escapeHtml(it.request_body || '(vacío)')}</pre>
        </div>
        <div class="section">
          <h3>Response body</h3>
          <pre>${escapeHtml(it.response_body || '(vacío)')}</pre>
        </div>
        <div class="section">
          <h3>Request headers</h3>
          <pre>${escapeHtml(JSON.stringify(it.request_headers || {}, null, 2))}</pre>
        </div>
      `;
    }

    function escapeHtml(s) {
      return String(s)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    }

    async function load() {
      const method = document.getElementById('method').value;
      const path = document.getElementById('path').value.trim();
      const u = new URL('/private/logs/api', location.origin);
      u.searchParams.set('token', TOKEN);
      u.searchParams.set('limit', '200');
      if (method) u.searchParams.set('method', method);
      if (path) u.searchParams.set('path_contains', path);
      const res = await fetch(u);
      if (!res.ok) {
        document.getElementById('list').innerHTML =
          `<div class="empty">Error ${res.status}: ${escapeHtml(await res.text())}</div>`;
        return;
      }
      const data = await res.json();
      items = data.items || [];
      const badge = document.getElementById('badge');
      badge.textContent = data.logging_enabled ? 'logging on' : 'logging off';
      badge.className = 'badge ' + (data.logging_enabled ? 'on' : 'off');
      const st = data.stats || {};
      document.getElementById('stats').textContent =
        ` · ${st.total || 0}/${st.max_entries || '?'} en memoria`;
      renderList();
      if (selectedId) {
        const cur = items.find(x => x.id === selectedId);
        if (cur) renderDetail(cur);
      }
    }

    document.getElementById('refresh').addEventListener('click', load);
    document.getElementById('method').addEventListener('change', load);
    document.getElementById('path').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') load();
    });
    document.getElementById('auto').addEventListener('change', (e) => {
      if (timer) clearInterval(timer);
      timer = null;
      if (e.target.checked) timer = setInterval(load, 3000);
    });
    document.getElementById('clear').addEventListener('click', async () => {
      if (!confirm('¿Borrar todos los logs en memoria?')) return;
      await fetch(qs('/private/logs/api'), { method: 'DELETE' });
      selectedId = null;
      load();
    });
    load();
  </script>
</body>
</html>
"""
