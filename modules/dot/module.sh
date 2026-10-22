link pull.plist ~/Library/LaunchAgents/dot.pull.plist
post_link load-pull-agent 'launchctl print user/$(id -u)/dot.pull >/dev/null 2>&1 || launchctl bootstrap user/$(id -u) ~/Library/LaunchAgents/dot.pull.plist' 'launchctl print user/$(id -u)/dot.pull >/dev/null'
