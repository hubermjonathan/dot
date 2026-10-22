link wallpaper.jpg ~/Pictures/wallpaper.jpg
link profile-picture.jpg ~/Pictures/profile-picture.jpg
link zoom-background.jpg ~/Pictures/zoom-background.jpg
formula defaultbrowser
cask desktoppr
post_link sudo-touchid "grep -qE '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid.so' /etc/pam.d/sudo_local 2>/dev/null || printf 'auth       sufficient     pam_tid.so\\n' | sudo tee -a /etc/pam.d/sudo_local >/dev/null" "grep -E '^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid.so' /etc/pam.d/sudo_local"
post_link dark-mode "osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to true'"
post_link dock-autohide 'defaults write com.apple.dock autohide -bool true'
post_link dock-no-magnification 'defaults write com.apple.dock magnification -bool false'
post_link dock-clear-apps 'defaults write com.apple.dock persistent-apps -array'
post_link dock-clear-others 'defaults write com.apple.dock persistent-others -array'
post_link dock-clear-recents 'defaults write com.apple.dock recent-apps -array'
post_link dock-hide-recents 'defaults write com.apple.dock show-recents -bool false'
post_link hot-corner-br 'defaults write com.apple.dock wvous-br-corner -int 4'
post_link clock-seconds 'defaults write com.apple.menuextra.clock ShowSeconds -bool true'
post_link hide-desktop-widgets 'defaults write com.apple.WindowManager showStandardWidgets -bool false'
post_link hide-stage-manager-widgets 'defaults write com.apple.WindowManager showStageManagerWidgets -bool false'
post_link no-edge-tiling 'defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false'
post_link no-top-edge-tiling 'defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false'
post_link no-tiling-option-key 'defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false'
post_link no-tiled-margins 'defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false'
post_link clear-notification-widgets "python3 -c \"import plistlib,subprocess,tempfile,os; r=subprocess.run(['defaults','export','com.apple.notificationcenterui','-'],capture_output=True); p=plistlib.loads(r.stdout); p['widgets']={'instances':[],'vers':1}; f=tempfile.NamedTemporaryFile(suffix='.plist',delete=False); plistlib.dump(p,f); f.close(); subprocess.run(['defaults','import','com.apple.notificationcenterui',f.name]); os.unlink(f.name)\""
# AppleFirstWeekday counts Sunday as 1, iCal counts it as 0
post_link week-starts-monday 'defaults write NSGlobalDomain AppleFirstWeekday -dict gregorian 2'
post_link calendar-week-starts-monday "defaults write com.apple.iCal 'first day of week' -int 1"
post_link natural-scroll-off 'defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false'
post_link fn-keys-standard 'defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true'
post_link no-auto-capitalize 'defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false'
post_link no-auto-period 'defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false'
post_link chrome-new-tab-right "defaults write com.google.Chrome NSUserKeyEquivalents -dict-add 'New Tab to the Right' '@^t'"
post_link terminal-default-profile "defaults write com.apple.Terminal 'Default Window Settings' -string Basic"
post_link terminal-startup-profile "defaults write com.apple.Terminal 'Startup Window Settings' -string Basic"
# defaultbrowser can't detect the current default here, so it would show the confirm dialog on every link
post_link default-browser "osascript -l JavaScript -e 'ObjC.import(\"AppKit\"); \$.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL(\$.NSURL.URLWithString(\"https:\")).path.js' | grep -q 'Google Chrome' || defaultbrowser chrome" "osascript -l JavaScript -e 'ObjC.import(\"AppKit\"); \$.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL(\$.NSURL.URLWithString(\"https:\")).path.js' | grep -q 'Google Chrome'"
post_link finder-new-window-target 'defaults write com.apple.finder NewWindowTarget -string PfLo'
post_link finder-new-window-path 'defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Downloads/"'
post_link finder-empty-old-trash 'defaults write com.apple.finder FXRemoveOldTrashItems -bool true'
post_link finder-hide-recent-tags 'defaults write com.apple.finder ShowRecentTags -bool false'
post_link activate-settings '/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u'
post_link set-wallpaper 'desktoppr ~/Pictures/wallpaper.jpg'
post_link profile-picture 'dscl . read /Users/$USER Picture | grep -q "$HOME/Pictures/profile-picture.jpg" && dscl . read /Users/$USER JPEGPhoto 2>&1 | grep -q '\''No such key'\'' || { sudo dscl . delete /Users/$USER JPEGPhoto 2>/dev/null; sudo dscl . create /Users/$USER Picture "$HOME/Pictures/profile-picture.jpg"; }'
# SIP refuses kickstart -k for NotificationCenter, SystemUIServer, and WindowManager, so killall stops them and kickstart starts any launchd didn't
post_link restart-ui 'killall Dock Finder NotificationCenter SystemUIServer WindowManager 2>/dev/null; sleep 1; for s in com.apple.Dock.agent com.apple.Finder com.apple.notificationcenterui.agent com.apple.SystemUIServer.agent com.apple.WindowManager.agent; do launchctl kickstart gui/$(id -u)/$s || exit 1; done'
provision finder-sidebar-reminder "echo 'MANUAL: Finder > Settings > Sidebar — uncheck Recents, Shared; check Pictures'"
