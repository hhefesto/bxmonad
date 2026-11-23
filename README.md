# xmonad in Bend

A port of [xmonad](https://xmonad.org) 0.18.1 (and later xmobar) to Bend.

## Where it stands

| Part | State |
| --- | --- |
| `XMonad.StackSet` (workspaces, screens, windows, floating) | **Ported**: `StackSet.bend`, `Num.bend` |
| `XMonad.Layout` (tile, the splits, Full, Tall, Mirror, Choose and their messages) | **Ported**: `Layout.bend` |
| `XMonad.Core`, `XMonad.Config` (the state, the events, the requests; the default configuration) | **Ported**: `Core.bend` |
| `XMonad.Operations` and `XMonad.Main`'s event handler (`windows`, `manage`, `focus`, `float`, the key and mouse bindings, every event xmonad handles) | **Ported**: `Operations.bend`, pure: an event and the state in, the new state and the X requests out |
| `XMonad.Main`'s launch and loop, the X side | **Ported**: `Main.bend` (the loop), `X.bend` and `x11.c` (one Xlib call or a few per effect, no decisions) |
| Left out for now | the mouse drags (mod-button1 moves a floating window, mod-button3 resizes it), Xinerama (one screen, the root's), the manageHook's two MPlayer rules, restart (mod-q), help (mod-shift-/), the state file, a user configuration |
| xmobar | Not started |

It is a working window manager: `nix build` (or `bend Main.bend -o
xmonad-bend` in `nix develop`) and run it on an X display.

    nix build .#xmonad-bend
    Xephyr :5 -screen 1280x800 &          # a nested X server to try it in
    DISPLAY=:5 ./result/bin/xmonad-bend

The keys are xmonad's defaults (mod is Alt): mod-shift-Return a terminal
(xterm), mod-j/k focus, mod-Return swap with the master, mod-space next
layout, mod-h/l shrink and expand the master area, mod-1..9 workspaces,
mod-shift-c close, mod-shift-q quit, and the rest of xmonad's list.

How it is built. The pure modules (`Num`, `StackSet`, `Layout`, `Core`,
`Operations`) pass `bend --check-only` with ALL PROOFS CHECK. `Main.bend` and
`X.bend` reach X11 through foreign effects (`x11.c`, spliced into the
program's C by `bend -o`), so a check of them names those defs ("defs that
depend on foreign effects"), and only those. Everything xmonad decides
happens in `Operations.bend`; `Main.bend` only sends the requests it
answers and asks X what xmonad asks about an event (a window's attributes,
WM_HINTS, WM_PROTOCOLS, WM_NORMAL_HINTS).

cata (`~/src/cata`) translated 66 of xmonad's 931 functions on its own; the
rest stop on X11's types, `==` and `compare` at a type variable, pattern
guards and guards with no fallback. The pure core is therefore written by
hand, function by function from `XMonad/StackSet.hs` and `XMonad/Layout.hs`;
each file's header says where it differs (for example `new` answers `Maybe`
where Haskell's calls `error`, and a layout is one data type instead of a
class).

## How it is checked

- **Laws.** `PROPOSED.bend` states 86 laws, most of them the properties
  xmonad's own test suite checks with QuickCheck (`tests/Properties/*.hs`),
  here for every value; `PROOF.bend` proves them. They are proposals: move
  them into a `LAWS.bend`, reword or drop them.

      bend PROOF.bend                  # ALL PROOFS CHECK
      bend PROOF.bend --verdict        # BendTT's kernel too: ALL PROOFS CHECK
      nix flake check                  # proofs, modules, mutants

  (`nix develop`'s bend, bend-frp's, has BendTT's kernel built in; with
  another bend, put Lean 4.34.0 on PATH for `--verdict`.)

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

  The window manager (24): an event xmonad does not handle changes
  nothing; windows leaves the windowset at f's answer (Hide told to the
  layouts it hid) and keeps the numlock mask; on one screen with no
  floating windows every window goes where the layout puts it; the default
  keys (mod-j, mod-shift-c, mod-space, mod-shift-q, mod-3, mod-shift-9);
  NumLock and CapsLock change no binding; scan takes the viewable and
  iconic windows and not the override-redirect or withdrawn ones; setFocusX
  gives the input focus unless WM_HINTS refuse it, and sends WM_TAKE_FOCUS
  to a window that asks for it; kill sends WM_DELETE_WINDOW to a window that
  takes it, else kills its client; a window with min size = max size is
  fixed (so floats), one with no hints is not, and its size is kept; a
  window hidden once waits for one UnmapNotify. Underneath: U32's == is
  reflexive (`u32_eq_refl`, bit by bit).

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
- **End to end, against xmonad itself.** `tests/e2e.sh` runs xmonad 0.18.1
  (its default configuration, launched from its own source by
  `tests/e2e/Ref.hs`, never reading `~/.config/xmonad`) and xmonad-bend, each
  on a private X server (Xvfb), gives both the same clients
  (`tests/e2e/Client.hs`: plain, fixed-size and transient windows that close
  on WM_DELETE_WINDOW, withdraw or are destroyed), keys and pointer moves and
  clicks, and after every step compares the two screens
  (`tests/e2e/Snap.hs`: every window's place in X's stacking order, map
  state, position, size, border and WM_STATE, and the input focus).

      nix build .#e2e-tools                 # xmonad-ref, e2e-client, e2e-snap
      REF=.../xmonad-ref WM=.../xmonad-bend CLIENT=.../e2e-client SNAP=.../e2e-snap \
        tests/e2e.sh tests/e2e/scenarios/basic.txt   # or: --random SEED STEPS

  `tests/e2e/scenarios/basic.txt` (29 steps) and 17 random runs
  (`tests/e2e-random.sh`, seeds 1-17, 80 or 100 steps each): 1,669 steps,
  every one the same on both. The comparison does catch a wrong window
  manager: with hide's `selectInput` left unmasked (one line of
  Operations.bend), seed 1 differs at 43 of 80 steps.
