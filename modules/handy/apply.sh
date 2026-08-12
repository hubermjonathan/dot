#!/usr/bin/env bash
# Merge the versioned Handy settings into its tauri-plugin-store file, then restart the app.
# Handy holds settings in memory and rewrites the whole store on any UI change, so it must be
# quit before writing. It reads the store at launch and never writes on quit, so this sticks.
set -euo pipefail

CONFIG="${1:-$HOME/.config/handy/handy.json}"
STORE="$HOME/Library/Application Support/com.pais.handy/settings_store.json"
MODEL_REPO="handy-computer/parakeet-unified-en-0.6b-gguf"
MODEL_REV="7e948f21b7bdbac698d3318db9d350f1096f3b6c"
MODEL_FILE="parakeet-unified-en-0.6b-Q8_0.gguf"

[ -f "$CONFIG" ] || { echo "missing: $CONFIG"; exit 1; }

if pgrep -x Handy >/dev/null; then
  osascript -e 'quit app "Handy"' >/dev/null 2>&1 || true
  for _ in $(seq 20); do pgrep -x Handy >/dev/null || break; sleep 0.25; done
  pgrep -x Handy >/dev/null && killall Handy 2>/dev/null || true
fi

mkdir -p "$(dirname "$STORE")"

# Deep-merge $CONFIG over store["settings"]. Objects merge per-key, arrays of objects merge by
# "id" (so the `custom` provider is patched, not the whole provider list replaced), scalars replace.
python3 - "$CONFIG" "$STORE" <<'PY'
import json, os, sys, tempfile

cfg_path, store_path = sys.argv[1], sys.argv[2]
patch = json.load(open(cfg_path))

store = {}
if os.path.exists(store_path):
    try:
        store = json.load(open(store_path))
    except (json.JSONDecodeError, OSError):
        store = {}
if not isinstance(store, dict):
    store = {}


def merge(base, patch):
    if isinstance(base, dict) and isinstance(patch, dict):
        out = dict(base)
        for k, v in patch.items():
            out[k] = merge(base.get(k), v)
        return out
    if isinstance(base, list) and isinstance(patch, list) \
            and all(isinstance(x, dict) and "id" in x for x in base + patch):
        out = [dict(x) for x in base]
        by_id = {x["id"]: i for i, x in enumerate(out)}
        for item in patch:
            if item["id"] in by_id:
                out[by_id[item["id"]]] = merge(out[by_id[item["id"]]], item)
            else:
                out.append(dict(item))
        return out
    return patch


settings = store.get("settings")
store["settings"] = merge(settings if isinstance(settings, dict) else {}, patch)

d = os.path.dirname(store_path)
fd, tmp = tempfile.mkstemp(dir=d, suffix=".tmp")
with os.fdopen(fd, "w") as f:
    json.dump(store, f, indent=2)
os.replace(tmp, store_path)
PY

# Pre-place the model in the shared HF hub cache so Handy finds it instead of prompting a download.
CACHE="${HF_HOME:-$HOME/.cache/huggingface}/hub"
SNAPSHOT="$CACHE/models--${MODEL_REPO//\//--}/snapshots/$MODEL_REV/$MODEL_FILE"
if [ ! -e "$SNAPSHOT" ]; then
  if command -v hf >/dev/null; then
    hf download "$MODEL_REPO" "$MODEL_FILE" --revision "$MODEL_REV" >/dev/null
  else
    echo "hf cli not found — Handy will download $MODEL_FILE on first use"
  fi
fi

open -gja Handy

cat <<'EOF'
handy: grant Microphone + Accessibility/Input Monitoring in System Settings on a fresh machine
       (TCC permissions cannot be scripted)
EOF
