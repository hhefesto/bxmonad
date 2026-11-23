#!/usr/bin/env zsh
# Breaks StackSet.bend and Layout.bend in small ways, one at a time, in a
# scratch copy, and checks that PROOF.bend then fails (each mutant should
# be "killed").  Needs bend in PATH ($BEND to override) and, for
# --verdict, Lean 4.34.0.
#   tests/mutants.sh            # bend PROOF.bend
#   tests/mutants.sh --verdict  # and BendTT's kernel
emulate -L zsh
set -u
root=${0:A:h:h}
bend=${BEND:-bend}
tmp=$(mktemp -d)
trap 'rm -rf $tmp' EXIT
export BEND_NO_TELEMETRY=1
extra=("$@")
killed=0 total=0

mutant() {  # name, file, sed -E expression
  local d=$tmp/$1
  mkdir -p $d
  cp $root/*.bend $d/
  sed -E -i "$3" $d/$2
  (( total++ ))
  if cmp -s $d/$2 $root/$2; then
    print "$1: not applied ($2 changed?)"
    return
  fi
  if $bend $d/PROOF.bend $extra 2>&1 | grep -q 'ALL PROOFS CHECK'; then
    print "$1: SURVIVED"
  else
    print "$1: killed"
    (( killed++ ))
  fi
}

# StackSet.bend
# focusUp no longer wraps from the top to the bottom
mutant wrap StackSet.bend 's/Stack\.top\(A, List\.reverse\(&2, A, t <> rs\), t\)/Stack{t, Nil{}, rs}/'
# swapUp at the top keeps the order instead of reversing it
mutant swapNil StackSet.bend 's/Stack\{t, List\.reverse\(&2, A, rs\), Nil\{\}\}/Stack{t, rs, Nil{}}/'
# insertUp puts the new window below the focus, not in it
mutant ins StackSet.bend 's/Some\{Stack\{a, l, t <> r\}\}/Some{Stack{t, l, a <> r}}/'
# Data.Map's delete keeps the key it should remove
mutant fdel StackSet.bend 's/(_ => Float\{k, v\} <> rest, )_ => rest,/\1_ => Float{k, v} <> rest,/'
# view from the hidden workspaces leaves the current one on the screen
mutant vhid StackSet.bend 's/StackSet\{Screen\{x, sc, sd\}, v, w <> /StackSet{Screen{w, sc, sd}, v, x <> /'
# focusMaster loses the window that was in focus
mutant fmgo StackSet.bend 's/Stack\{x, Nil\{\}, List\.append\(&2, A, rest, t <> rs\)\}/Stack{x, Nil{}, List.append(\&2, A, rest, rs)}/'
# swapMaster focuses the top window instead of moving the focused one there
mutant smgo StackSet.bend 's/Stack\{t, Nil\{\}, List\.append\(&2, A, rest, x <> rs\)\}/Stack{x, Nil{}, List.append(\&2, A, rest, t <> rs)}/'

# Layout.bend
# splitVertically's last row keeps the whole height
mutant splitLast Layout.bend 's/U32\.sub\(sh, smallh\)/sh/'
# tile uses two columns when the windows exactly fill the master column
mutant tileEq Layout.bend 's/Cmp\.is_le\(N\.Int\.cmp\(N\.Int\.of\(n\), nmaster\)\)/Cmp.is_lt(N.Int.cmp(N.Int.of(n), nmaster))/'
# mirrorRect swaps the position only
mutant mirror Layout.bend 's/      Rectangle\{y, x, h, w\}/      Rectangle{y, x, w, h}/'
# Full shows nothing
mutant full Layout.bend 's/      \[Place\{W\.Stack\.focus\(A, s\), r\}\]/      Nil{}/'
# Tall drops the last window
mutant zip Layout.bend 's/    case x <> xt r <> rt:/    case x <> xt r <> Nil{}:\n      Nil{}\n    case x <> xt r <> rt:/'
# NextLayout from the left side goes straight to Full
mutant next Layout.bend 's/Choose\.choose\(CL\{\}, CL\{\}, a, b, Some\{x\}, None\{\}, hide\)/Choose.choose(CL{}, CR{}, a, b, None{}, None{}, hide)/'

print "$killed of $total killed"
(( killed == total ))
