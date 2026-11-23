#!/usr/bin/env zsh
# End-to-end comparison: xmonad 0.18.1 itself and xmonad-bend, each on a
# private X server (Xvfb), given the same clients and the same keys and
# pointer moves; after every step both screens are read (tests/e2e/Snap.hs:
# each window's stacking place, map state, place, border and WM_STATE, and
# the focus) and compared.
#
#   tests/e2e.sh SCENARIO          # a file of steps, one per line
#   tests/e2e.sh --random SEED N   # N random steps from SEED
#
# Steps:
#   spawn NAME [fixed W H] [transient PARENT]   a client (tests/e2e/Client.hs)
#   key KEYS                                    xdotool key KEYS (alt+j, ...)
#   withdraw NAME | destroy NAME                the client unmaps / destroys
#   pointer X Y | click BUTTON | modclick BUTTON
#
# Needs: Xvfb and xdotool on PATH; REF (xmonad, tests/e2e/Ref.hs built),
# WM (xmonad-bend), CLIENT and SNAP (built from tests/e2e/). Prints the
# steps where the two differ and "same N, differ M"; exits 1 if any differ.
setopt no_unset
here=${0:A:h}
: ${REF:?} ${WM:?} ${CLIENT:?} ${SNAP:?}
SETTLE=${SETTLE:-0.25}
out=$(mktemp -d /tmp/xb-e2e.XXXXXX)

scenario() {
  if [[ $1 == --random ]]; then
    "$here/e2e-random.sh" $2 $3
  else
    cat $1
  fi
}

# run DISPLAY WMCMD STEPS OUT: the steps on a fresh X server, a snapshot
# after each
run() {
  local D=$1 wmcmd=$2 steps=$3 snaps=$4
  local -A pid
  Xvfb $D -screen 0 1280x800x24 -nolisten tcp > $out/xvfb$D.log 2>&1 &
  local xp=$!
  sleep 0.6
  DISPLAY=$D ${=wmcmd} > $out/wm$D.log 2>&1 &
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
    esac
    sleep $SETTLE
    i=$((i + 1))
    { echo "== $i: $line"; DISPLAY=$D $SNAP; } >> $snaps
  done < $steps
  kill $wp 2>/dev/null || true
  for p in ${(v)pid}; do kill $p 2>/dev/null || true; done
  kill $xp 2>/dev/null || true
  wait 2>/dev/null || true
}

# two free displays (no lock file), so runs side by side never share one
freedisp() { local n=$1; while [[ -e /tmp/.X$n-lock || -e /tmp/.X11-unix/X$n ]]; do n=$((n + 1)); done; echo $n; }
d1=$(freedisp $((90 + $$ % 400)))
d2=$(freedisp $((d1 + 1)))
scenario $@ > $out/steps
mkdir -p $out/ref
run :$d1 "$REF $out/ref" $out/steps $out/ref.txt &
run :$d2 "$WM" $out/steps $out/bend.txt &
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
