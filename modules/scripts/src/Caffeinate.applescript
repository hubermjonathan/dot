set isRunning to (do shell script "pgrep -x caffeinate || true")
if isRunning is not "" then
	do shell script "pkill -x caffeinate"
	display alert "Caffeinate" message "Off" giving up after 1
else
	do shell script "caffeinate -di &>/dev/null &"
	display alert "Caffeinate" message "On" giving up after 1
end if
