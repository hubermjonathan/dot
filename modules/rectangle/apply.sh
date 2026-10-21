#!/usr/bin/env bash
# Rectangle refuses a symlinked RectangleConfig.json and asks before importing one, so write its defaults directly.
set -euo pipefail

CONFIG="$HOME/.config/rectangle/RectangleConfig.json"
DOMAIN="com.knollsoft.Rectangle"

python3 - "$CONFIG" "$DOMAIN" <<'PY'
import json, subprocess, sys

cfg_path, domain = sys.argv[1], sys.argv[2]
cfg = json.load(open(cfg_path))

for key, payload in cfg.get("defaults", {}).items():
    if not payload:
        continue
    [(t, v)] = payload.items()
    flag = {"bool": "-bool", "int": "-int", "float": "-float", "string": "-string"}[t]
    val = "true" if (t == "bool" and v) else "false" if t == "bool" else str(v)
    subprocess.run(["defaults", "write", domain, key, flag, val], check=True)

for k, v in cfg.get("shortcuts", {}).items():
    subprocess.run([
        "defaults", "write", domain, k, "-dict",
        "keyCode", "-int", str(v["keyCode"]),
        "modifierFlags", "-int", str(v["modifierFlags"]),
    ], check=True)
PY
