# The numbers xmonad needs that Base lacks: integers and rationals.
#
# An Int is Pos{n}, the integer n, or Neg{n}, the integer -(n+1): each
# integer is exactly one term, so equal integers are equal terms. A Rat is
# num / (den+1), not reduced: two Rats are the same number when their cross
# products agree (Rat.is_eq), not when their terms do.

import Base

type Int is Data:
  Int.Pos{n: Nat}
  Int.Neg{n: Nat}

type Rat is Data:
  Rat{num: Int, den: Nat}

def Int.of(n: Nat) -> Int:
  Int.Pos{n}

# n - m for Nats, as an Int
def Int.sub.nat(n: Nat, m: Nat) -> Int:
  match n m:
    case 0n 0n:
      Int.Pos{0n}
    case 0n 1n+q:
      Int.Neg{q}
    case 1n+p 0n:
      Int.Pos{1n+p}
    case 1n+p 1n+q:
      Int.sub.nat(p, q)

def Int.neg(a: Int) -> Int:
  match a:
    case Int.Pos{0n}:
      Int.Pos{0n}
    case Int.Pos{1n+p}:
      Int.Neg{p}
    case Int.Neg{p}:
      Int.Pos{1n+p}

def Int.add(a: Int, b: Int) -> Int:
  match a b:
    case Int.Pos{n} Int.Pos{m}:
      Int.Pos{Nat.add(n, m)}
    case Int.Pos{n} Int.Neg{m}:
      Int.sub.nat(n, 1n+m)
    case Int.Neg{n} Int.Pos{m}:
      Int.sub.nat(m, 1n+n)
    case Int.Neg{n} Int.Neg{m}:
      Int.Neg{1n+Nat.add(n, m)}

def Int.sub(a: Int, b: Int) -> Int:
  Int.add(a, Int.neg(b))

def Int.mul.nat(a: Int, +m: Nat) -> Int:
  match a:
    case Int.Pos{n}:
      Int.Pos{Nat.mul(n, m)}
    case Int.Neg{n}:
      Int.neg(Int.Pos{Nat.mul(1n+n, m)})

def Int.mul(a: Int, b: Int) -> Int:
  match b:
    case Int.Pos{m}:
      Int.mul.nat(a, m)
    case Int.Neg{m}:
      Int.neg(Int.mul.nat(a, 1n+m))

def Int.cmp(a: Int, b: Int) -> Cmp:
  match a b:
    case Int.Pos{n} Int.Pos{m}:
      Nat.cmp(n, m)
    case Int.Pos{n} Int.Neg{m}:
      GT{}
    case Int.Neg{n} Int.Pos{m}:
      LT{}
    case Int.Neg{n} Int.Neg{m}:
      Nat.cmp(m, n)

def Int.is_eq(a: Int, b: Int) -> Bool:
  match a b:
    case Int.Pos{n} Int.Pos{m}:
      Nat.is_eq(n, m)
    case Int.Neg{n} Int.Neg{m}:
      Nat.is_eq(n, m)
    case _ _:
      False{}

def Int.show(a: Int) -> String:
  match a:
    case Int.Pos{n}:
      Nat.show(n)
    case Int.Neg{n}:
      "-" ++ Nat.show(1n+n)

def Rat.of(n: Int, d: Nat) -> Rat:
  Rat{n, d}

def Rat.is_eq(a: Rat, b: Rat) -> Bool:
  match a b:
    case Rat{n, +d} Rat{m, +e}:
      Int.is_eq(Int.mul.nat(n, 1n+e), Int.mul.nat(m, 1n+d))
