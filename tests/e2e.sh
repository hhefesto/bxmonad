#!/usr/bin/env zsh
# End-to-end comparison: xmonad 0.18.1 itself and xmonad-bend, each on a
# private X server (Xvfb), given the same clients and the same keys and
# pointer moves; after every step both screens are read (tests/e2e/Snap.hs:
# each window's stacking place, map state, place, border and WM_STATE, and
# the focus) and compared.
#
#   tests/e2e.sh SCENARIO          # a file of steps, one per line
#   tests/e2e.sh --random SEED N   # N random steps from SEED
#   SCREENS="1280x800 1024x768" tests/e2e.sh ...   # two screens, Xinerama
#
# Steps:
#   spawn NAME [fixed W H] [transient PARENT] [class CLASS]
#                                               a client (tests/e2e/Client.hs)
#   key KEYS                                    xdotool key KEYS (alt+j, ...)
#   withdraw NAME | destroy NAME                the client unmaps / destroys
#   pointer X Y | click BUTTON | modclick BUTTON
#   drag BUTTON X Y X1 Y1 [X2 Y2 ...]          mod-BUTTON pressed at X Y, the
#                                               pointer through each point,
#                                               released at the last
#   restart                                     `xmonad --restart`: the window
#                                               manager saves its state and
#                                               runs itself again
#
# Needs: Xvfb, xdotool (and for SCREENS, Xephyr) on PATH; REF (xmonad, tests/e2e/Ref.hs built),
# WM (xmonad-bend), CLIENT, SNAP and RESTART (built from tests/e2e/). Prints the
# steps where the two differ and "same N, differ M"; exits 1 if any differ.
#
# A restart: xmonad runs "xmonad" from PATH, which here is a script running
# REF again on its own directory; xmonad-bend runs itself, its directories
# (XMONAD_DATA_DIR and the rest) set to one of the test's own, so neither
# touches the user's.
setopt no_unset
here=${0:A:h}
: ${REF:?} ${WM:?} ${CLIENT:?} ${SNAP:?} ${RESTART:?}
SETTLE=${SETTLE:-0.25}
out=$(mktemp -d /tmp/xb-e2e.XXXXXX)

# SCREENS (say "1280x800 1024x768"): the X server is Xephyr with those
# screens side by side under Xinerama (in a private Xvfb of its own);
# else one Xvfb screen of 1280x800
SCREENS=${SCREENS:-}
if [[ -n $SCREENS ]]; then
  ws=0 hs=0
  for s in ${=SCREENS}; do ws=$((ws + ${s%x*})); (( ${s#*x} > hs )) && hs=${s#*x}; done
else
  ws=1280 hs=800
fi
export E2E_W=$ws E2E_H=$hs

scenario() {
  if [[ $1 == --random ]]; then
    "$here/e2e-random.sh" $2 $3
  else
    cat $1
  fi
}

# the display number a server started with -displayfd wrote to file $1
display() {
  local i
  for i in {1..100}; do [[ -s $1 ]] && break; sleep 0.05; done
  echo :$(<$1)
}

# run TAG WMCMD STEPS OUT: the steps on a fresh X server (it picks a free
# display, -displayfd, so runs side by side never share one), a snapshot
# after each
run() {
  local tag=$1 wmcmd=$2 steps=$3 snaps=$4
  local -A pid
  local D hp=
  if [[ -n $SCREENS ]]; then
    Xvfb -displayfd 3 -screen 0 $((ws + 64))x$((hs + 64))x24 -nolisten tcp 3> $out/host-$tag > $out/xhost-$tag.log 2>&1 &
    hp=$!
    local H=$(display $out/host-$tag) scr=() s
    for s in ${=SCREENS}; do scr+=(-screen $s); done
    DISPLAY=$H Xephyr -displayfd 3 +xinerama $scr -nolisten tcp 3> $out/disp-$tag > $out/x-$tag.log 2>&1 &
  else
    Xvfb -displayfd 3 -screen 0 1280x800x24 -nolisten tcp 3> $out/disp-$tag > $out/x-$tag.log 2>&1 &
  fi
  local xp=$!
  D=$(display $out/disp-$tag)
  sleep 0.3
  mkdir -p $out/path-$tag $out/dirs-$tag
  printf '#!/bin/sh\nexec %s %s\n' $REF $out/ref > $out/path-$tag/xmonad
  chmod +x $out/path-$tag/xmonad
  DISPLAY=$D PATH=$out/path-$tag:$PATH XMONAD_DATA_DIR=$out/dirs-$tag XMONAD_CONFIG_DIR=$out/dirs-$tag XMONAD_CACHE_DIR=$out/dirs-$tag ${=wmcmd} > $out/wm-$tag.log 2>&1 &
  local wp=$!
  sleep 0.6
  local i=0 line
  while IFS= read -r line; do
    [[ -z $line || $line == \#* ]] && continue
    local a=(${=line})
    case $a[1] in
      spawn) DISPLAY=$D $CLIENT ${a[2,-1]} &
        local last=$!
        pid[$a[2]]=$last ;;
      key) DISPLAY=$D xdotool key $a[2] ;;
      withdraw) if [[ -n ${pid[$a[2]]:-} ]]; then kill -USR1 $pid[$a[2]] 2>/dev/null || true; fi ;;
      destroy) if [[ -n ${pid[$a[2]]:-} ]]; then kill -USR2 $pid[$a[2]] 2>/dev/null || true; fi ;;
      pointer) DISPLAY=$D xdotool mousemove $a[2] $a[3] ;;
      click) DISPLAY=$D xdotool click $a[2] ;;
      modclick) DISPLAY=$D xdotool keydown alt click $a[2] keyup alt ;;
      drag) DISPLAY=$D xdotool mousemove $a[3] $a[4]; sleep 0.1
        DISPLAY=$D xdotool keydown alt mousedown $a[2]; sleep 0.2
        local j=5
        while (( j < $#a )); do
          DISPLAY=$D xdotool mousemove $a[j] $a[j+1]; sleep 0.2
          j=$((j + 2))
        done
        DISPLAY=$D xdotool mouseup $a[2] keyup alt ;;
      restart) DISPLAY=$D $RESTART; sleep 1.5 ;;
    esac
    sleep $SETTLE
    i=$((i + 1))
    { echo "== $i: $line"; DISPLAY=$D $SNAP; } >> $snaps
  done < $steps
  kill $wp 2>/dev/null || true
  for p in ${(v)pid}; do kill $p 2>/dev/null || true; done
  kill $xp 2>/dev/null || true
  if [[ -n $hp ]]; then kill $hp 2>/dev/null || true; fi
  wait 2>/dev/null || true
}

scenario $@ > $out/steps
mkdir -p $out/ref
run ref "$REF $out/ref" $out/steps $out/ref.txt &
run bend "$WM" $out/steps $out/bend.txt &
wait
# compare step by step
awk -v A=$out/ref.txt -v B=$out/bend.txt 'BEGIN {
  while ((getline l < A) > 0) { if (l ~ /^== /) { n++; h[n] = l } else ra[n] = ra[n] l "\n" }
  m = 0; while ((getline l < B) > 0) { if (l ~ /^== /) m++; else rb[m] = rb[m] l "\n" }
  same = 0; diff = 0
  for (i = 1; i <= n; i++) {
    if (ra[i] == rb[i]) same++
    else { diff++; if (diff <= 5) printf "%s\n-- xmonad:\n%s-- xmonad-bend:\n%s", h[i], ra[i], rb[i] }
  }
  printf "same %d, differ %d\n", same, diff
  exit diff > 0
}'
rc=$?
echo "logs: $out"
exit $rc
