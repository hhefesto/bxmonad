#!/usr/bin/env zsh
# The state file's differential test against xmonad 0.18.1's own
# readStateFile and writeStateToFile:
#   tests/statefile-diff.sh SEED COUNT
# GHC: a ghc with xmonad's dependencies and QuickCheck (cata's .#ghc-xmonad);
# XMONAD: an unpacked xmonad-0.18.1 (its src/ is compiled in); BEND: bend.
set -eu
here=${0:A:h}
seed=${1:-1} count=${2:-100}
: ${GHC:?a ghc with QuickCheck} ${XMONAD:?an unpacked xmonad-0.18.1} ${BEND:=bend}
out=$(mktemp -d)
$GHC -O0 -i$XMONAD/src -i$here/e2e/ref -outputdir $out -o $out/gen $here/gen/GenState.hs > $out/ghc.log 2>&1 || { cat $out/ghc.log; exit 1 }
$out/gen $seed $count > $here/StateCases.bend
(cd $here && BEND_NO_TELEMETRY=1 $BEND StateFileDiff.bend | grep -v '^Hint')
rm -rf $out
