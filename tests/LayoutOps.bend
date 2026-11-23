# The layout differential test's vocabulary: an operation of XMonad.Layout
# with its arguments, and a case (an operation and what xmonad's own Haskell
# answers, written by tests/gen/GenLayout.hs into tests/LayoutCases.bend).
# Windows are Nats.

import Base
import ../StackSet.bend as W
import ../Num.bend as N
import ../Layout.bend as L
import ./Ops.bend as O

type LOp is Data:
  LTile{f: N.Rat, r: L.Rectangle, nmaster: N.Int, n: Nat}
  LSplitV{n: N.Int, r: L.Rectangle}
  LSplitH{n: N.Int, r: L.Rectangle}
  LSplitHBy{f: N.Rat, r: L.Rectangle}
  LSplitVBy{f: N.Rat, r: L.Rectangle}
  LRun{l: L.Layout, r: L.Rectangle, s: Maybe<&2, W.Stack<Nat>>}
  LMsg{l: L.Layout, m: L.Msg}
  LDesc{l: L.Layout}

type LCase is Data:
  LCase{op: LOp, want: String}

# Showing values, in the words tests/gen/GenLayout.hs writes

def show.rect(r: L.Rectangle) -> String:
  match r:
    case L.Rectangle{x, y, w, h}:
      "R(" ++ U32.show(x) ++ "," ++ U32.show(y) ++ "," ++ U32.show(w) ++ "," ++ U32.show(h) ++ ")"

def show.rects(xs: List<&2, L.Rectangle>) -> String:
  O.show.list(~L.Rectangle, ~show.rect, xs)

def show.pair(p: L.Rectangle & L.Rectangle) -> String:
  match p:
    case (a, b):
      "(" ++ show.rect(a) ++ "," ++ show.rect(b) ++ ")"

def show.place(p: L.Place<Nat>) -> String:
  match p:
    case L.Place{w, r}:
      Nat.show(w) ++ ":" ++ show.rect(r)

def show.side(s: L.Side) -> String:
  match s:
    case L.CL{}:
      "CL"
    case L.CR{}:
      "CR"

def show.layout(l: L.Layout) -> String:
  match l:
    case L.Full{}:
      "Full"
    case L.Tall{n, d, f}:
      "Tall(" ++ N.Int.show(n) ++ "," ++ N.Rat.show(N.Rat.norm(d)) ++ "," ++ N.Rat.show(N.Rat.norm(f)) ++ ")"
    case L.Mirror{x}:
      "Mirror(" ++ show.layout(x) ++ ")"
    case L.Choose{s, a, b}:
      "Choose(" ++ show.side(s) ++ "," ++ show.layout(a) ++ "," ++ show.layout(b) ++ ")"
