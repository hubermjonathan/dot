link RectangleConfig.json ~/.config/rectangle/RectangleConfig.json
link apply.sh ~/.config/rectangle/apply.sh
cask rectangle
post_link apply-settings '~/.config/rectangle/apply.sh'
post_link restart-rectangle 'pgrep -x Rectangle >/dev/null && killall Rectangle; open -gja Rectangle'
