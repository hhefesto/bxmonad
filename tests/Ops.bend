# The differential test's vocabulary: an operation of XMonad.StackSet with
# its arguments, what it answers, and a case (a set, an operation, and what
# xmonad's own Haskell answers there, written by tests/gen/Gen.hs into
# tests/Cases.bend). The set is StackSet<Nat, Nat, Nat, Nat, Nat>: tags,
# layouts, windows, screen ids and screen details all numbers, as in
# xmonad's own tests (there windows are Chars).

import Base
import ../StackSet.bend as W
import ../Num.bend as N

type Op is Data:
  OView{i: Nat}
  OGreedyView{i: Nat}
  OFocusUp{}
  OFocusDown{}
  OSwapUp{}
  OSwapDown{}
  OSwapMaster{}
  OShiftMaster{}
  OFocusMaster{}
  OFocusWindow{w: Nat}
  OInsertUp{w: Nat}
  ODelete{w: Nat}
  ODelete_{w: Nat}
  OShift{i: Nat}
  OShiftWin{i: Nat, w: Nat}
  ORenameTag{o: Nat, n: Nat}
  OEnsureTags{l: Nat, ts: List<&2, Nat>}
  OFloat{w: Nat, r: W.RationalRect}
  OSink{w: Nat}
  OPeek{}
  OIndex{}
  OFindTag{w: Nat}
  OMember{w: Nat}
  OAllWindows{}
  OCurrentTag{}
  OLookupWorkspace{sc: Nat}
  OTagMember{t: Nat}
  OWorkspaces{}
  OScreens{}
  OFilterCurrent{w: Nat}
  ONew{l: Nat, ts: List<&2, Nat>, ms: List<&2, Nat>}

type Case is Data:
  Case{s: W.StackSet<Nat, Nat, Nat, Nat, Nat>, op: Op, want: String}

# Showing values, in the words tests/gen/Gen.hs writes for the same values

def show.nat(n: Nat) -> String:
  Nat.show(n)

def List.map.d(~A: Data, ~B: Data, ~f: A -> B, xs: List<&2, A>) -> List<&2, B>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      f(x) <> List.map.d(~A, ~B, ~f, rest)

def show.list(~A: Data, ~f: A -> String, xs: List<&2, A>) -> String:
  "[" ++ String.join(List.map.d(~A, ~String, ~f, xs), ",") ++ "]"

def show.maybe(~A: Data, ~f: A -> String, m: Maybe<&2, A>) -> String:
  match m:
    case None{}:
      "N"
    case Some{x}:
      "J(" ++ f(x) ++ ")"

def show.bool(b: Bool) -> String:
  match b:
    case True{}:
      "T"
    case False{}:
      "F"

def show.stack(s: W.Stack<Nat>) -> String:
  match s:
    case W.Stack{f, u, d}:
      "S(" ++ Nat.show(f) ++ "," ++ show.list(~Nat, ~show.nat, u) ++ "," ++ show.list(~Nat, ~show.nat, d) ++ ")"

def show.ws(w: W.Workspace<Nat, Nat, Nat>) -> String:
  match w:
    case W.Workspace{t, l, st}:
      "W(" ++ Nat.show(t) ++ "," ++ Nat.show(l) ++ "," ++ show.maybe(~W.Stack<Nat>, ~show.stack, st) ++ ")"

def show.scr(c: W.Screen<Nat, Nat, Nat, Nat, Nat>) -> String:
  match c:
    case W.Screen{w, s, d}:
      "C(" ++ show.ws(w) ++ "," ++ Nat.show(s) ++ "," ++ Nat.show(d) ++ ")"

def show.rat(r: N.Rat) -> String:
  match r:
    case N.Rat{n, d}:
      N.Int.show(n) ++ "/" ++ Nat.show(1n+d)

def show.rr(r: W.RationalRect) -> String:
  match r:
    case W.RationalRect{a, b, c, d}:
      "R(" ++ show.rat(a) ++ "," ++ show.rat(b) ++ "," ++ show.rat(c) ++ "," ++ show.rat(d) ++ ")"

def show.float(f: W.Float<Nat>) -> String:
  match f:
    case W.Float{w, r}:
      Nat.show(w) ++ ":" ++ show.rr(r)

def show.ss(s: W.StackSet<Nat, Nat, Nat, Nat, Nat>) -> String:
  match s:
    case W.StackSet{c, v, h, f}:
      "SS(" ++ show.scr(c) ++ "," ++ show.list(~W.Screen<Nat, Nat, Nat, Nat, Nat>, ~show.scr, v) ++ "," ++ show.list(~W.Workspace<Nat, Nat, Nat>, ~show.ws, h) ++ "," ++ show.list(~W.Float<Nat>, ~show.float, f) ++ ")"
