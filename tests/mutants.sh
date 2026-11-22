#!/usr/bin/env zsh
# Breaks StackSet.bend in small ways, one at a time, in a scratch copy, and
# checks that PROOF.bend then fails (each mutant should be "killed").
# Needs bend in PATH ($BEND to override) and, for --verdict, Lean 4.34.0.
#   tests/mutants.sh            # bend PROOF.bend
#   tests/mutants.sh --verdict  # and BendTT's kernel
emulate -L zsh
set -u
root=${0:A:h:h}
bend=${BEND:-bend}
tmp=$(mktemp -d)
trap 'rm -rf $tmp' EXIT
export BEND_NO_TELEMETRY=1
killed=0 total=0

mutant() {  # name, sed -E expression
  local d=$tmp/$1
  mkdir -p $d
  cp $root/{StackSet,Num,PROPOSED,PROOF}.bend $d/
  sed -E -i "$2" $d/StackSet.bend
  (( total++ ))
  if cmp -s $d/StackSet.bend $root/StackSet.bend; then
    print "$1: not applied (StackSet.bend changed?)"
    return
  fi
  if $bend $d/PROOF.bend "$@[3,-1]" 2>&1 | grep -q 'ALL PROOFS CHECK'; then
    print "$1: SURVIVED"
  else
    print "$1: killed"
    (( killed++ ))
  fi
}

extra=("$@")
# focusUp no longer wraps from the top to the bottom
mutant wrap 's/Stack\.top\(A, List\.reverse\(&2, A, t <> rs\), t\)/Stack{t, Nil{}, rs}/' $extra
# swapUp at the top keeps the order instead of reversing it
mutant swapNil 's/Stack\{t, List\.reverse\(&2, A, rs\), Nil\{\}\}/Stack{t, rs, Nil{}}/' $extra
# insertUp puts the new window below the focus, not in it
mutant ins 's/Some\{Stack\{a, l, t <> r\}\}/Some{Stack{t, l, a <> r}}/' $extra
# Data.Map's delete keeps the key it should remove
mutant fdel 's/(_ => Float\{k, v\} <> rest, )_ => rest,/\1_ => Float{k, v} <> rest,/' $extra
# view from the hidden workspaces leaves the current one on the screen
mutant vhid 's/StackSet\{Screen\{x, sc, sd\}, v, w <> /StackSet{Screen{w, sc, sd}, v, x <> /' $extra
# focusMaster loses the window that was in focus
mutant fmgo 's/Stack\{x, Nil\{\}, List\.append\(&2, A, rest, t <> rs\)\}/Stack{x, Nil{}, List.append(\&2, A, rest, rs)}/' $extra
# swapMaster focuses the top window instead of moving the focused one there
mutant smgo 's/Stack\{t, Nil\{\}, List\.append\(&2, A, rest, x <> rs\)\}/Stack{x, Nil{}, List.append(\&2, A, rest, t <> rs)}/' $extra

print "$killed of $total killed"
(( killed == total ))
