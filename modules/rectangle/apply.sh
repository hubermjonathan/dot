#!/usr/bin/env bash
# Translate Rectangle's exported JSON into `defaults write` calls + import shortcuts via plist.
set -euo pipefail

CONFIG="${1:-$HOME/.config/rectangle/RectangleConfig.json}"
DOMAIN="com.knollsoft.Rectangle"

[ -f "$CONFIG" ] || { echo "missing: $CONFIG"; exit 1; }

# Defaults: each key has exactly one of {bool,int,float,string} or empty (skip).
python3 - "$CONFIG" "$DOMAIN" <<'PY'
import json, plistlib, subprocess, sys, tempfile, os

cfg_path, domain = sys.argv[1], sys.argv[2]
cfg = json.load(open(cfg_path))

for key, payload in cfg.get("defaults", {}).items():
    if not payload:
        continue
    [(t, v)] = payload.items()
    flag = {"bool": "-bool", "int": "-int", "float": "-float", "string": "-string"}[t]
    val = "true" if (t == "bool" and v) else "false" if t == "bool" else str(v)
    subprocess.run(["defaults", "write", domain, key, flag, val], check=True)

shortcuts = cfg.get("shortcuts", {})
if shortcuts:
    plist = {k: {"keyCode": v["keyCode"], "modifierFlags": v["modifierFlags"]}
             for k, v in shortcuts.items()}
    with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as f:
        plistlib.dump(plist, f)
        path = f.name
    try:
        for k in plist:
            subprocess.run(["defaults", "delete", domain, k], check=False,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for k, v in plist.items():
            subprocess.run([
                "defaults", "write", domain, k, "-dict",
                "keyCode", "-int", str(v["keyCode"]),
                "modifierFlags", "-int", str(v["modifierFlags"]),
            ], check=True)
    finally:
        os.unlink(path)
PY
