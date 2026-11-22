# xmonad in Bend

A port of [xmonad](https://xmonad.org) 0.18.1 (and later xmobar) to Bend.

## Where it stands

| Part | State |
| --- | --- |
| `XMonad.StackSet` (workspaces, screens, windows, floating) | **Ported**: `StackSet.bend`, `Num.bend` |
| `XMonad.Core`, `Layout`, `Operations`, `ManageHook`, `Config`, `Main` | Not yet: they run on X11 (windows, displays, events) |
| xmobar | Not started |

cata (`~/src/cata`) translated 66 of xmonad's 931 functions on its own; the
rest stop on X11's types, `==` and `compare` at a type variable, pattern
guards and guards with no fallback. StackSet, the pure core, is therefore
written by hand, function by function from `XMonad/StackSet.hs`; the header of
`StackSet.bend` says where it differs (for example `new` answers `Maybe`
where Haskell's calls `error`).

## How it is checked

- **Laws.** `PROPOSED.bend` states 41 of the properties xmonad's test suite
  checks with QuickCheck (`tests/Properties/*.hs`), as laws for every value;
  `PROOF.bend` proves them. They are proposals: move them into a `LAWS.bend`,
  reword or drop them.

      bend PROOF.bend                                   # ALL PROOFS CHECK
      PATH=<lean4-4.34.0>/bin:$PATH bend PROOF.bend --verdict

  The laws: focusUp/focusDown and swapUp/swapDown undo each other (on a stack
  and on the set); swaps, swapMaster and shiftMaster keep the focus;
  focusMaster keeps the order; focusMaster, shiftMaster and swapMaster are
  idempotent; Stack is a Functor; modify' changes only the current
  workspace's windows; screens is current then visible; mapLayout and
  mapWorkspace by the identity change nothing; insertUp of a member changes
  nothing, of a new window puts it in focus and makes it a member, and is
  idempotent; a window floated then sunk leaves the set as it was; view is
  idempotent. A law that needs `==` or `compare` to behave takes it as a
  hypothesis (`eqA(a, a)` is True).

- **Mutants.** `tests/mutants.sh [--verdict]` breaks `StackSet.bend` in 7
  small ways; `PROOF.bend` must fail on each (7 of 7 killed).

- **Differential test.** `tests/diff.sh SEED COUNT` builds random stack sets
  and operations in Haskell (`tests/gen/Gen.hs`, against xmonad's own
  `XMonad.StackSet`), and compares every answer with the Bend port's
  (`tests/Diff.bend`): 9,200 cases over four seeds, 0 differ. It needs GHC
  with QuickCheck, `XMONAD` (xmonad's source) and `BEND`.
