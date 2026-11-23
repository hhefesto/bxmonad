#!/usr/bin/env zsh
# The differential test against xmonad's own XMonad.Layout:
#   tests/layout-diff.sh SEED COUNT
# GHC: a ghc with QuickCheck (cata's .#ghc-xmonad has it); XMONAD: an
# unpacked xmonad-0.18.1 (its src/ is compiled in); BEND: bend.
set -eu
here=${0:A:h}
seed=${1:-1} count=${2:-1000}
: ${GHC:?a ghc with QuickCheck} ${XMONAD:?an unpacked xmonad-0.18.1} ${BEND:=bend}
out=$(mktemp -d)
$GHC -O0 -i$XMONAD/src -outputdir $out -o $out/genl $here/gen/GenLayout.hs > $out/ghc.log 2>&1 || { cat $out/ghc.log; exit 1 }
$out/genl $seed $count > $here/LayoutCases.bend
(cd $here && BEND_NO_TELEMETRY=1 $BEND LayoutDiff.bend | grep -v '^Hint')
rm -rf $out
