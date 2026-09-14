from collections import defaultdict
from pathlib import Path

p = Path(r"C:\Users\LR\.cursor\projects\d-vexsoluciones-profimar\uploads\Untitled-1-L1-L2988-0.txt")
lines = [ln.strip() for ln in p.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]
rows = []
for i, ln in enumerate(lines):
    if i == 0 and "artid" in ln.lower():
        continue
    parts = ln.split("\t") if "\t" in ln else ln.split()
    if len(parts) < 2:
        continue
    art, ade = parts[0].strip(), parts[1].strip()
    rows.append((art, ade))

by: dict[str, list[str]] = defaultdict(list)
for art, ade in rows:
    by[ade].append(art)

repeated = {k: v for k, v in sorted(by.items()) if len(v) > 1}
print(f"Total filas: {len(rows)}")
print(f"adeDescripcion unicos: {len(by)}")
print(f"adeDescripcion repetidos: {len(repeated)}")
print("---")
for ade, arts in repeated.items():
    arts_join = ", ".join(arts)
    print(f"{ade}\t({len(arts)})\t{arts_join}")
