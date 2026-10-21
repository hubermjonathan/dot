formula tailscale
provision start-daemon 'ls /Library/LaunchDaemons/*tailscale.plist >/dev/null 2>&1 || sudo brew services start tailscale' 'pgrep -x tailscaled'
provision up 'tailscale status >/dev/null 2>&1 || sudo tailscale up --operator=$USER' 'tailscale status'
