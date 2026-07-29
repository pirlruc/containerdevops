#!/usr/bin/env bash
# Fail if dive efficiency percent is below the org floor.
# Usage: check-image-efficiency.sh <min_percent> [dive.json]
set -euo pipefail
MIN_PCT="${1:?min efficiency percent required}"
INPUT="${2:--}"

python3 - "${MIN_PCT}" "${INPUT}" <<'PY'
import json
import sys

min_pct = float(sys.argv[1])
path = sys.argv[2]
raw = sys.stdin.read() if path == "-" else open(path, encoding="utf-8").read()
try:
    data = json.loads(raw)
except json.JSONDecodeError as exc:
    print(f"invalid dive json: {exc}", file=sys.stderr)
    raise SystemExit(2)

eff = None
if isinstance(data, dict):
    for key in ("imageEfficientPercent", "efficiency", "efficientPercent"):
        if key in data:
            eff = float(data[key])
            break
    if eff is None and isinstance(data.get("result"), dict):
        result = data["result"]
        for key in ("efficiency", "imageEfficientPercent"):
            if key in result:
                eff = float(result[key])
                break

if eff is None or eff < 0:
    print("could not parse dive efficiency from JSON", file=sys.stderr)
    raise SystemExit(2)

print(f"dive efficiency={eff:.2f}% (min {min_pct})")
raise SystemExit(0 if eff >= min_pct else 1)
PY
