# The layout differential test: every case of tests/LayoutCases.bend (an
# operation and what xmonad's own XMonad.Layout answers) run through the
# Bend port; it prints how many answers are the same and each that differs.
#
#   tests/layout-diff.sh SEED COUNT

import Base
import ../StackSet.bend as W
import ../Num.bend as N
import ../Layout.bend as L
import ./Ops.bend as O
import ./LayoutOps.bend as P
import ./LayoutCases.bend as C

# what the port answers to op, in LayoutOps.bend's words
def got(op: P.LOp) -> String:
  match op:
    case P.LTile{f, r, nm, n}:
      P.show.rects(L.tile(f, r, nm, n))
    case P.LSplitV{n, r}:
      P.show.rects(L.splitVertically.int(n, r))
    case P.LSplitH{n, r}:
      P.show.rects(L.Rect.mirrorAll(L.splitVertically.int(n, L.mirrorRect(r))))
    case P.LSplitHBy{f, r}:
      P.show.pair(L.splitHorizontallyBy(f, r))
    case P.LSplitVBy{f, r}:
      P.show.pair(L.splitVerticallyBy(f, r))
    case P.LRun{l, r, s}:
      O.show.list(~L.Place<Nat>, ~P.show.place, L.Layout.run(Nat, l, r, s))
    case P.LMsg{l, m}:
      O.show.maybe(~L.Layout, ~P.show.layout, L.handleMessage(l, m))
    case P.LDesc{l}:
      L.Layout.description(l)

def check(cs: List<&2, P.LCase>, +i: Nat, +same: Nat, +differ: Nat, +report: String) -> String:
  match cs:
    case Nil{}:
      "same " ++ Nat.show(same) ++ ", differ " ++ Nat.show(differ) ++ "\n" ++ report
    case P.LCase{op, +want} <> rest:
      +g = got(op)
      +ok = String.eq(want, g)
      check(rest, 1n+i, Bool.pick(Nat, ok, 1n+same, same), Bool.pick(Nat, ok, differ, 1n+differ), Bool.pick(String, ok, report, report ++ "case " ++ Nat.show(i) ++ "\n  xmonad: " ++ want ++ "\n  bend:   " ++ g ++ "\n"))

def main() -> IO(Unit):
  IO.print(check(C.cases(), 1n, 0n, 0n, ""))
