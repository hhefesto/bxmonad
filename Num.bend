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

def Rat.neg(a: Rat) -> Rat:
  match a:
    case Rat{n, d}:
      Rat{Int.neg(n), d}

def Rat.add(a: Rat, b: Rat) -> Rat:
  match a b:
    case Rat{n, +d} Rat{m, +e}:
      Rat{Int.add(Int.mul.nat(n, 1n+e), Int.mul.nat(m, 1n+d)), Nat.sub(Nat.mul(1n+d, 1n+e), 1n)}

def Rat.sub(a: Rat, b: Rat) -> Rat:
  Rat.add(a, Rat.neg(b))

def Rat.cmp(a: Rat, b: Rat) -> Cmp:
  match a b:
    case Rat{n, +d} Rat{m, +e}:
      Int.cmp(Int.mul.nat(n, 1n+e), Int.mul.nat(m, 1n+d))

# gcd by Euclid's steps; b shrinks at each, so 1 + b steps are enough
def Nat.gcd.go(fuel: Nat, a: Nat, +b: Nat) -> Nat:
  match fuel:
    case 0n:
      a
    case 1n+k:
      match b:
        case 0n:
          a
        case 1n+p:
          Nat.gcd.go(k, b, Nat.mod(a, b))

def Nat.gcd(a: Nat, +b: Nat) -> Nat:
  Nat.gcd.go(1n+b, a, b)

def Int.abs.nat(a: Int) -> Nat:
  match a:
    case Int.Pos{n}:
      n
    case Int.Neg{n}:
      1n+n

# a / g for a g dividing a
def Int.div.nat(a: Int, +g: Nat) -> Int:
  match a:
    case Int.Pos{n}:
      Int.Pos{Nat.div(n, g)}
    case Int.Neg{n}:
      Int.Neg{Nat.sub(Nat.div(1n+n, g), 1n)}

# the Rat in lowest terms, as Haskell's Rational always is
def Rat.norm(r: Rat) -> Rat:
  match r:
    case Rat{+n, d}:
      +q = Nat.add(1n, d)
      +g = Nat.gcd(Int.abs.nat(n), q)
      Rat{Int.div.nat(n, g), Nat.sub(Nat.div(q, g), 1n)}

def Rat.show(r: Rat) -> String:
  match r:
    case Rat{n, d}:
      Int.show(n) ++ "/" ++ Nat.show(1n+d)
