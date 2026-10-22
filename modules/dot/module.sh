link pull.plist ~/Library/LaunchAgents/dot.pull.plist
post_link load-pull-agent 'launchctl print gui/$(id -u)/dot.pull >/dev/null 2>&1 || launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/dot.pull.plist' 'launchctl print gui/$(id -u)/dot.pull >/dev/null'
