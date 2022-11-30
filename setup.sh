# load setup files
for setup in */; do
  read -p "set up ${setup%?}? " -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    source "${setup}setup.sh"
  else
    echo
  fi
done

unset setup

