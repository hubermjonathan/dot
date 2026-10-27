formula hf ollama
cask handy
provision start-ollama 'brew services start ollama >/dev/null'
provision pull-gemma 'for _ in $(seq 30); do curl -sf http://127.0.0.1:11434/api/tags >/dev/null && break; sleep 1; done; ollama list | grep -q gemma4:12b-mlx || ollama pull gemma4:12b-mlx' 'ollama list | grep -q gemma4:12b-mlx'
post_link apply-settings './apply.sh handy.json' 'test -f "$HOME/Library/Application Support/com.pais.handy/settings_store.json"'
