# xmonad in Bend

A port of [xmonad](https://xmonad.org) 0.18.1 (and later xmobar) to Bend.

## Where it stands

| Part | State |
| --- | --- |
| `XMonad.StackSet` (workspaces, screens, windows, floating) | **Ported**: `StackSet.bend`, `Num.bend` |
| `XMonad.Layout` (tile, the splits, Full, Tall, Mirror, Choose and their messages) | **Ported**: `Layout.bend` |
| `XMonad.Core`, `Operations`, `ManageHook`, `Config`, `Main` | Not yet: they run on X11 (windows, displays, events) |
| xmobar | Not started |

cata (`~/src/cata`) translated 66 of xmonad's 931 functions on its own; the
rest stop on X11's types, `==` and `compare` at a type variable, pattern
guards and guards with no fallback. The pure core is therefore written by
hand, function by function from `XMonad/StackSet.hs` and `XMonad/Layout.hs`;
each file's header says where it differs (for example `new` answers `Maybe`
where Haskell's calls `error`, and a layout is one data type instead of a
class).

## How it is checked

- **Laws.** `PROPOSED.bend` states 62 laws, most of them the properties
  xmonad's own test suite checks with QuickCheck (`tests/Properties/*.hs`),
  here for every value; `PROOF.bend` proves them. They are proposals: move
  them into a `LAWS.bend`, reword or drop them.

      bend PROOF.bend                                   # ALL PROOFS CHECK
      PATH=<lean4-4.34.0>/bin:$PATH bend PROOF.bend --verdict

  StackSet: focusUp/focusDown and swapUp/swapDown undo each other (on a
  stack and on the set); swaps, swapMaster and shiftMaster keep the focus;
  focusMaster keeps the order; focusMaster, shiftMaster and swapMaster are
  idempotent; Stack is a Functor; modify' changes only the current
  workspace's windows; screens is current then visible; mapLayout and
  mapWorkspace by the identity change nothing; insertUp of a member changes
  nothing, of a new window puts it in focus and makes it a member, and is
  idempotent; a window floated then sunk leaves the set as it was; view is
  idempotent. A law that needs `==` or `compare` to behave takes it as a
  hypothesis (`eqA(a, a)` is True).

  Layout: mirrorRect twice is the identity; splitVertically n gives max n 1
  rows, each at r's x and as wide (splitHorizontally: y and height); both
  halves of splitVerticallyBy keep x and width (splitHorizontallyBy: y and
  height); tile with one window and one master fills the screen; tile
  gives max n 1 rectangles; Tall places every window (ratio not 0 or 1);
  Full shows the focused window on the whole screen; no windows, no places;
  Mirror is the layout turned; descriptions; Full answers no message;
  IncMasterN adds to the master windows; the default layout cycles Tall,
  Mirror Tall, Full, Tall, and a Choose on the left is gone through first;
  JumpToLayout "Full" lands on Full.

- **Mutants.** `tests/mutants.sh [--verdict]` breaks `StackSet.bend` and
  `Layout.bend` in 13 small ways; `PROOF.bend` must fail on each (13 of 13
  killed).

- **Differential tests.** Random cases are answered by xmonad's own Haskell
  and compared with the Bend port's answers. They need GHC with QuickCheck
  and X11 (cata's `.#ghc-xmonad`), `XMONAD` (xmonad's source) and `BEND`.
  - `tests/diff.sh SEED COUNT`: stack sets and 32 StackSet operations
    (`tests/gen/Gen.hs`, `tests/Diff.bend`): 9,200 cases over four seeds,
    0 differ.
  - `tests/layout-diff.sh SEED COUNT`: tile, the splits, runLayout,
    handleMessage and description on random layout trees
    (`tests/gen/GenLayout.hs`, `tests/LayoutDiff.bend`): 11,300 cases over
    five seeds, 0 differ.
