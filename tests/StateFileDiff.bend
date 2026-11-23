# The state file's differential test: every case of tests/StateCases.bend
# (a state file's text, and what xmonad 0.18.1 writes again after reading
# it, or NONE) run through StateFile.bend's read and then its show; it
# prints how many answers are the same and each that differs.
#
#   tests/statefile-diff.sh SEED COUNT

import Base
import ../StateFile.bend as SF
import ./StateCases.bend as C

def got.of(m: SF.WR()) -> String:
  match m:
    case None{}:
      "NONE"
    case Some{s}:
      SF.show(s)

def got(+text: String) -> String:
  got.of(SF.read(text))

# where two texts first differ (the length of their common start)
def first.diff(a: String, b: String, +i: Nat) -> Nat:
  match a b:
    case SCon{x, ra} SCon{y, rb}:
      Bool.pick(Nat, U32.is_eq(Char.to_u32(x), Char.to_u32(y)), first.diff(ra, rb, 1n+i), i)
    case _ _:
      i

# 120 characters of s from 50 before the place p
def around(+s: String, +p: Nat) -> String:
  String.take(String.drop(s, Nat.sub(p, 50n)), 120n)

def check(cs: List<&2, C.Case>, +i: Nat, +same: Nat, +differ: Nat, +report: String) -> String:
  match cs:
    case Nil{}:
      "same " ++ Nat.show(same) ++ ", differ " ++ Nat.show(differ) ++ "\n" ++ report
    case C.Case{+text, +want} <> rest:
      +g = got(text)
      +ok = String.eq(want, g)
      +p = first.diff(want, g, 0n)
      check(rest, 1n+i, Bool.pick(Nat, ok, 1n+same, same), Bool.pick(Nat, ok, differ, 1n+differ), Bool.pick(String, ok, report, report ++ "case " ++ Nat.show(i) ++ ", from character " ++ Nat.show(p) ++ "\n  text:   " ++ around(text, p) ++ "\n  xmonad: " ++ around(want, p) ++ "\n  bend:   " ++ around(g, p) ++ "\n"))

def main() -> IO(Unit):
  IO.print(check(C.cases(), 1n, 0n, 0n, ""))
