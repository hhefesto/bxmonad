#!/usr/bin/env zsh
# N random end-to-end steps from SEED (for tests/e2e.sh --random SEED N):
# clients come (some fixed-size or transient, so floating) and go, keys of
# xmonad's default bindings are pressed, the pointer moves and clicks.
RANDOM=$1
n=$2
keys=(alt+j alt+k alt+m alt+Return alt+shift+j alt+shift+k alt+space
  alt+shift+space alt+h alt+l alt+comma alt+period alt+t alt+n alt+Tab
  alt+shift+Tab alt+1 alt+2 alt+3 alt+shift+1 alt+shift+2 alt+shift+3
  alt+shift+c alt+w alt+shift+w)
live=()
next=1
pick() { print -r -- ${live[$(( RANDOM % $#live + 1 ))]}; }
for i in {1..$n}; do
  r=$(( RANDOM % 100 ))
  if (( $#live == 0 || r < 22 )); then
    name=t$next; next=$((next + 1))
    f=$(( RANDOM % 10 ))
    if (( f == 0 )); then
      echo "spawn $name fixed $(( 100 + RANDOM % 300 )) $(( 80 + RANDOM % 200 ))"
    elif (( f == 1 && $#live > 0 )); then
      echo "spawn $name transient $(pick)"
    else
      echo "spawn $name"
    fi
    live+=$name
  elif (( r < 30 )); then
    v=$(pick); live=(${live:#$v}); echo "destroy $v"
  elif (( r < 34 )); then
    v=$(pick); live=(${live:#$v}); echo "withdraw $v"
  elif (( r < 42 )); then
    echo "pointer $(( RANDOM % 1280 )) $(( RANDOM % 800 ))"
  elif (( r < 46 )); then
    echo "click 1"
  else
    echo "key ${keys[$(( RANDOM % $#keys + 1 ))]}"
  fi
done
