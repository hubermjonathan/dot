# The dot.pull launch agent leaves this log only when a pull fails.
[[ -f ~/Library/Logs/dot-pull.log ]] && print "dot: the last pull failed. See ~/Library/Logs/dot-pull.log"
