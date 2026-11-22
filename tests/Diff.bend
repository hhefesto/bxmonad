# The differential test: every case of tests/Cases.bend (a set, an
# operation, and what xmonad's own XMonad.StackSet answers) run through the
# Bend port; it prints how many answers are the same and each that differs.
#
#   tests/diff.sh SEED COUNT

import Base
import ../StackSet.bend as W
import ../Num.bend as N
import ./Ops.bend as O
import ./Cases.bend as C

def ss(s: W.StackSet<Nat, Nat, Nat, Nat, Nat>) -> String:
  O.show.ss(s)

def got.filter(m: Maybe<&2, W.Stack<Nat>>, +w: Nat) -> String:
  match m:
    case None{}:
      "X"
    case Some{st}:
      O.show.maybe(~W.Stack<Nat>, ~O.show.stack, W.Stack.filter(~Nat, ~Nat, ~(w => x => W.Stack.ne(~Nat, ~Nat.is_eq, w, x)), w, st))

# what the port answers to op on s, in Ops.bend's words
def got(op: O.Op, s: W.StackSet<Nat, Nat, Nat, Nat, Nat>) -> String:
  match op:
    case O.OView{i}:
      ss(W.view(~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, Nat, Nat, Nat, i, s))
    case O.OGreedyView{i}:
      ss(W.greedyView(~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, Nat, Nat, Nat, i, s))
    case O.OFocusUp{}:
      ss(W.focusUp(Nat, Nat, Nat, Nat, Nat, s))
    case O.OFocusDown{}:
      ss(W.focusDown(Nat, Nat, Nat, Nat, Nat, s))
    case O.OSwapUp{}:
      ss(W.swapUp(Nat, Nat, Nat, Nat, Nat, s))
    case O.OSwapDown{}:
      ss(W.swapDown(Nat, Nat, Nat, Nat, Nat, s))
    case O.OSwapMaster{}:
      ss(W.swapMaster(Nat, Nat, Nat, Nat, Nat, s))
    case O.OShiftMaster{}:
      ss(W.shiftMaster(Nat, Nat, Nat, Nat, Nat, s))
    case O.OFocusMaster{}:
      ss(W.focusMaster(Nat, Nat, Nat, Nat, Nat, s))
    case O.OFocusWindow{w}:
      ss(W.focusWindow(~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, Nat, Nat, w, s))
    case O.OInsertUp{w}:
      ss(W.insertUp(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, w, s))
    case O.ODelete{w}:
      ss(W.delete(~Nat, ~Nat.cmp, Nat, Nat, Nat, Nat, w, s))
    case O.ODelete_{w}:
      ss(W.delete_(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, w, s))
    case O.OShift{i}:
      ss(W.shift(~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, Nat, Nat, i, s))
    case O.OShiftWin{i, w}:
      ss(W.shiftWin(~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, ~Nat, ~Nat.is_eq, Nat, Nat, i, w, s))
    case O.ORenameTag{o, n}:
      ss(W.renameTag(~Nat, ~Nat.is_eq, ~Nat, ~Nat, Nat, Nat, o, n, s))
    case O.OEnsureTags{l, ts}:
      ss(W.ensureTags(~Nat, ~Nat.is_eq, ~Nat, ~Nat, Nat, Nat, l, ts, s))
    case O.OFloat{w, r}:
      ss(W.float(~Nat, ~Nat.cmp, Nat, Nat, Nat, Nat, w, r, s))
    case O.OSink{w}:
      ss(W.sink(~Nat, ~Nat.cmp, Nat, Nat, Nat, Nat, w, s))
    case O.OPeek{}:
      O.show.maybe(~Nat, ~O.show.nat, W.peek(Nat, Nat, Nat, Nat, Nat, s))
    case O.OIndex{}:
      O.show.list(~Nat, ~O.show.nat, W.index(Nat, Nat, Nat, Nat, Nat, s))
    case O.OFindTag{w}:
      O.show.maybe(~Nat, ~O.show.nat, W.findTag(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, w, s))
    case O.OMember{w}:
      O.show.bool(W.member(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, w, s))
    case O.OAllWindows{}:
      O.show.list(~Nat, ~O.show.nat, W.allWindows(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, s))
    case O.OCurrentTag{}:
      Nat.show(W.currentTag(Nat, Nat, Nat, Nat, Nat, s))
    case O.OLookupWorkspace{sc}:
      O.show.maybe(~Nat, ~O.show.nat, W.lookupWorkspace(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, sc, s))
    case O.OTagMember{t}:
      O.show.bool(W.tagMember(~Nat, ~Nat.is_eq, Nat, Nat, Nat, Nat, t, s))
    case O.OWorkspaces{}:
      O.show.list(~W.Workspace<Nat, Nat, Nat>, ~O.show.ws, W.workspaces(Nat, Nat, Nat, Nat, Nat, s))
    case O.OScreens{}:
      O.show.list(~W.Screen<Nat, Nat, Nat, Nat, Nat>, ~O.show.scr, W.screens(Nat, Nat, Nat, Nat, Nat, s))
    case O.OFilterCurrent{w}:
      got.filter(W.Workspace.stack(Nat, Nat, Nat, W.Screen.workspace(Nat, Nat, Nat, Nat, Nat, W.current(Nat, Nat, Nat, Nat, Nat, s))), w)
    case O.ONew{l, ts, ms}:
      O.show.maybe(~W.StackSet<Nat, Nat, Nat, Nat, Nat>, ~ss, W.new(Nat, Nat, Nat, Nat, l, ts, ms))

def check(cs: List<&2, O.Case>, +i: Nat, +same: Nat, +differ: Nat, +report: String) -> String:
  match cs:
    case Nil{}:
      "same " ++ Nat.show(same) ++ ", differ " ++ Nat.show(differ) ++ "\n" ++ report
    case O.Case{s, op, +want} <> rest:
      +g = got(op, s)
      +ok = String.eq(want, g)
      check(rest, 1n+i, Bool.pick(Nat, ok, 1n+same, same), Bool.pick(Nat, ok, differ, 1n+differ), Bool.pick(String, ok, report, report ++ "case " ++ Nat.show(i) ++ "\n  xmonad: " ++ want ++ "\n  bend:   " ++ g ++ "\n"))

def main() -> IO(Unit):
  IO.print(check(C.cases(), 1n, 0n, 0n, ""))
