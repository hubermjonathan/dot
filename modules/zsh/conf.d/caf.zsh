caf() {
  local state=off
  launchctl print system/dot.caf 2>/dev/null | grep -q 'state = running' && state=on

  case "${1:-toggle}" in
    status)
      echo "caffeinate:   $state"
      if pmset -g | grep -q 'SleepDisabled[[:space:]]*1'; then
        echo "disablesleep: on"
      else
        echo "disablesleep: off"
      fi
      return ;;
    on)  [[ $state == on ]]  && { echo "Already caffeinated"; return; } ;;
    off) [[ $state == off ]] && { echo "Already decaffeinated"; return; } ;;
    toggle) ;;
    *) echo "Usage: caf [on|off|status]"; return 1 ;;
  esac

  if [[ $state == off ]]; then
    sudo launchctl kickstart system/dot.caf || return 1
    echo "Your Mac is now caffeinated"
  else
    sudo launchctl kill TERM system/dot.caf || return 1
    sudo pmset -a sleep 1 disablesleep 0 || return 1
    echo "Your Mac has been decaffeinated"
  fi
}
