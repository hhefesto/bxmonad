# XMonad.Layout in Bend: the rectangles a layout gives the windows (tile and
# the splits), and the layouts xmonad ships, Full, Tall, Mirror and Choose
# (|||), with the messages they answer.
#
# What it means. A layout, given the screen's rectangle and the current
# workspace's stack, places windows: a list of (window, rectangle), the
# windows drawn in that order. A message (Shrink, NextLayout, ...) gives a
# new layout, or none when the layout does not answer it (Haskell's
# Nothing: "unchanged").
#
# Where this differs from XMonad.Layout:
# - Haskell's layouts are a class, each its own type, and messages are
#   Typeable values of any type. Here a layout is one data type, Layout
#   (Full, Tall, Mirror of one, Choose of two), and a message one data type,
#   Msg, with the messages these layouts know. A message no layout here
#   answers changes nothing, as in Haskell.
# - Haskell's runLayout and handleMessage run in X; these layouts never touch
#   X, so here they are plain functions. runLayout's new layout is always
#   Nothing for them, so Layout.run answers the placements only.
# - A Rectangle's x and y are X11's Int32 and its width and height Word32;
#   all four are U32s here, the positions in two's complement: Int32's + and
#   - are U32's, so every rectangle is the same 32 bits as X11's.
# - A Tall's ratios are N.Rats; floor(w * frac), the master column's width,
#   is exact while |numerator| * denominator < 2^32 (Haskell's Rational is
#   unbounded; xmonad's ratios are like 1/2 and 3/100).
# - handleMessage, for Choose, sends Hide to a layout it has just made
#   (Haskell's `hide`), which is no part of the old one; Bend demands that
#   every recursion shrinks, so Layout.handle counts down a fuel of twice
#   the layout's size plus two, more than any message needs (each message
#   goes at most once down each level, NextLayout at most twice).

import Base
import ./StackSet.bend as W
import ./Num.bend as N

# Rectangles -------------------------------------------------------------------

type Rectangle is Data:
  Rectangle{x: U32, y: U32, w: U32, h: U32}

def mirrorRect(r: Rectangle) -> Rectangle:
  match r:
    case Rectangle{x, y, w, h}:
      Rectangle{y, x, h, w}

# splitVertically n r: n rows down r, each r's height divided by the rows
# left, the last taking what remains; [r] when n < 2
def splitVertically.pos(m: Nat, r: Rectangle) -> List<&2, Rectangle>:
  match m:
    case 0n:
      [r]
    case 1n+ +k:
      match r:
        case Rectangle{+sx, +sy, +sw, +sh}:
          +smallh = U32.div(sh, U32.from_nat(1n+1n+k))
          Rectangle{sx, sy, sw, smallh} <> splitVertically.pos(k, Rectangle{sx, U32.add(sy, smallh), sw, U32.sub(sh, smallh)})

def splitVertically(n: Nat, r: Rectangle) -> List<&2, Rectangle>:
  match n:
    case 0n:
      [r]
    case 1n+m:
      splitVertically.pos(m, r)

# Haskell's n is an Int: a negative one is [r] too
def splitVertically.int(n: N.Int, r: Rectangle) -> List<&2, Rectangle>:
  match n:
    case N.Int.Pos{k}:
      splitVertically(k, r)
    case N.Int.Neg{k}:
      [r]

def Rect.mirrorAll(xs: List<&2, Rectangle>) -> List<&2, Rectangle>:
  match xs:
    case Nil{}:
      Nil{}
    case r <> rest:
      mirrorRect(r) <> Rect.mirrorAll(rest)

def splitHorizontally(n: Nat, r: Rectangle) -> List<&2, Rectangle>:
  Rect.mirrorAll(splitVertically(n, mirrorRect(r)))

# floor(w * p / q) mod 2^32, for p * q < 2^32: (w div q) * p wraps as the
# answer does, and (w mod q) * p is below q * p
def Rect.scale.pos(+w: U32, +p: U32, +q: U32) -> U32:
  U32.add(U32.mul(U32.div(w, q), p), U32.div(U32.mul(U32.mod(w, q), p), q))

# floor(-(w * p / q)) mod 2^32: minus the ceiling
def Rect.scale.neg(+w: U32, +p: U32, +q: U32) -> U32:
  U32.sub(0, U32.add(Rect.scale.pos(w, p, q), Bool.pick(U32, U32.is_zero(U32.mod(U32.mul(U32.mod(w, q), p), q)), 0, 1)))

# floor(w * f), as Haskell's floor (fromIntegral w * f) :: Word32
def Rect.scale(+w: U32, f: N.Rat) -> U32:
  match f:
    case N.Rat{N.Int.Pos{n}, d}:
      Rect.scale.pos(w, U32.from_nat(n), U32.from_nat(1n+d))
    case N.Rat{N.Int.Neg{n}, d}:
      Rect.scale.neg(w, U32.from_nat(1n+n), U32.from_nat(1n+d))

# splitHorizontallyBy f r: r cut in two columns, the left floor(w * f) wide
def splitHorizontallyBy(f: N.Rat, r: Rectangle) -> Rectangle & Rectangle:
  match r:
    case Rectangle{+sx, +sy, +sw, +sh}:
      +lw = Rect.scale(sw, f)
      (Rectangle{sx, sy, lw, sh}, Rectangle{U32.add(sx, lw), sy, U32.sub(sw, lw), sh})

def Rect.mirrorBoth(p: Rectangle & Rectangle) -> Rectangle & Rectangle:
  match p:
    case (a, b):
      (mirrorRect(a), mirrorRect(b))

# splitVerticallyBy f r: r cut in two rows, the top floor(h * f) high
def splitVerticallyBy(f: N.Rat, r: Rectangle) -> Rectangle & Rectangle:
  Rect.mirrorBoth(splitHorizontallyBy(f, mirrorRect(r)))

def tile.cols(+nmaster: N.Int, n: Nat, p: Rectangle & Rectangle) -> List<&2, Rectangle>:
  match p:
    case (r1, r2):
      List.append(&2, Rectangle, splitVertically.int(nmaster, r1), splitVertically.int(N.Int.sub(N.Int.of(n), nmaster), r2))

# tile frac r nmaster n: n windows, nmaster in a master column frac of r
# wide, the rest in a column beside it; one column when n <= nmaster or
# nmaster is 0
def tile(f: N.Rat, +r: Rectangle, +nmaster: N.Int, +n: Nat) -> List<&2, Rectangle>:
  W.Bool.if(List<&2, Rectangle>, Bool.or(Cmp.is_le(N.Int.cmp(N.Int.of(n), nmaster)), N.Int.is_eq(nmaster, N.Int.of(0n))), _ => splitVertically(n, r), _ => tile.cols(nmaster, n, splitHorizontallyBy(f, r)))

# Layouts ----------------------------------------------------------------------

type Side is Data:
  CL{}
  CR{}

type Layout is Data:
  Full{}
  Tall{nmaster: N.Int, delta: N.Rat, frac: N.Rat}
  Mirror{l: Layout}
  Choose{side: Side, l: Layout, r: Layout}

def Side.is_eq(a: Side, b: Side) -> Bool:
  match a b:
    case CL{} CL{}:
      True{}
    case CR{} CR{}:
      True{}
    case _ _:
      False{}

def Layout.size(l: Layout) -> Nat:
  match l:
    case Full{}:
      1n
    case Tall{_, _, _}:
      1n
    case Mirror{m}:
      1n+Layout.size(m)
    case Choose{_, a, b}:
      1n+Nat.add(Layout.size(a), Layout.size(b))

# description: the layout's name, as xmonad shows it
def Layout.description(l: Layout) -> String:
  match l:
    case Full{}:
      "Full"
    case Tall{_, _, _}:
      "Tall"
    case Mirror{m}:
      "Mirror " ++ Layout.description(m)
    case Choose{CL{}, a, _}:
      Layout.description(a)
    case Choose{CR{}, _, b}:
      Layout.description(b)

# xmonad's default: Tall 1 (3/100) (1/2) ||| Mirror of it ||| Full
def Layout.tiled() -> Layout:
  Tall{N.Int.of(1n), N.Rat{N.Int.of(3n), 99n}, N.Rat{N.Int.of(1n), 1n}}

def Layout.default() -> Layout:
  Choose{CL{}, Layout.tiled(), Choose{CL{}, Mirror{Layout.tiled()}, Full{}}}

# Placing windows --------------------------------------------------------------

# a window and where it goes
type Place<-A: Data> is Data:
  Place{win: A, rect: Rectangle}

def Place.zip(-A: Data, xs: List<&2, A>, rs: List<&2, Rectangle>) -> List<&2, Place<A>>:
  match xs rs:
    case x <> xt r <> rt:
      Place{x, r} <> Place.zip(A, xt, rt)
    case _ _:
      Nil{}

def Place.mirror(-A: Data, xs: List<&2, Place<A>>) -> List<&2, Place<A>>:
  match xs:
    case Nil{}:
      Nil{}
    case Place{a, r} <> rest:
      Place{a, mirrorRect(r)} <> Place.mirror(A, rest)

def Place.drop(-A: Data, xs: List<&2, Place<A>>, n: N.Int) -> List<&2, Place<A>>:
  match n:
    case N.Int.Pos{k}:
      List.drop(&2, Place<A>, xs, k)
    case N.Int.Neg{k}:
      xs

def Place.take(-A: Data, xs: List<&2, Place<A>>, n: N.Int) -> List<&2, Place<A>>:
  match n:
    case N.Int.Pos{k}:
      List.take(&2, Place<A>, xs, k)
    case N.Int.Neg{k}:
      Nil{}

def Rat.zero() -> N.Rat:
  N.Rat{N.Int.of(0n), 0n}

def Rat.one() -> N.Rat:
  N.Rat{N.Int.of(1n), 0n}

def Tall.pick(-A: Data, z: Bool, o: Bool, lay: List<&2, Place<A>>, +n: N.Int) -> List<&2, Place<A>>:
  match z o:
    case True{} _:
      Place.drop(A, lay, n)
    case False{} True{}:
      Place.take(A, lay, n)
    case False{} False{}:
      lay

# Tall's pureLayout: the stack's windows, top to bottom, zipped with tile's
# rectangles; a ratio of 0 leaves out the master column, of 1 the other
def Tall.layout(-A: Data, +n: N.Int, +frac: N.Rat, +r: Rectangle, s: W.Stack<A>) -> List<&2, Place<A>>:
  +ws = W.Stack.integrate(A, s)
  Tall.pick(A, N.Rat.is_eq(frac, Rat.zero()), N.Rat.is_eq(frac, Rat.one()), Place.zip(A, ws, tile(frac, r, n, List.length(&2, A, ws))), n)

# runLayout: where the layout puts the windows of a stack (or none) on r
def Layout.run(-A: Data, l: Layout, +r: Rectangle, m: Maybe<&2, W.Stack<A>>) -> List<&2, Place<A>>:
  match l m:
    case _ None{}:
      Nil{}
    case Full{} Some{s}:
      [Place{W.Stack.focus(A, s), r}]
    case Tall{n, _, f} Some{s}:
      Tall.layout(A, n, f, r, s)
    case Mirror{x} Some{s}:
      Place.mirror(A, Layout.run(A, x, mirrorRect(r), Some{s}))
    case Choose{CL{}, a, _} Some{s}:
      Layout.run(A, a, r, Some{s})
    case Choose{CR{}, _, b} Some{s}:
      Layout.run(A, b, r, Some{s})

# Messages ---------------------------------------------------------------------

type Msg is Data:
  Shrink{}
  Expand{}
  IncMasterN{d: N.Int}
  NextLayout{}
  FirstLayout{}
  NextNoWrap{}
  Hide{}
  ReleaseResources{}
  JumpToLayout{name: String}

# max 0 x and min 1 x, as Haskell's max and min on Rational
def Rat.max0(+x: N.Rat) -> N.Rat:
  Bool.pick(N.Rat, Cmp.is_le(N.Rat.cmp(Rat.zero(), x)), x, Rat.zero())

def Rat.min1(+x: N.Rat) -> N.Rat:
  Bool.pick(N.Rat, Cmp.is_le(N.Rat.cmp(Rat.one(), x)), Rat.one(), x)

def Int.max0(+x: N.Int) -> N.Int:
  match x:
    case N.Int.Pos{k}:
      N.Int.Pos{k}
    case N.Int.Neg{k}:
      N.Int.of(0n)

# Tall's pureMessage: Shrink and Expand move the ratio by delta, kept within
# 0 and 1; IncMasterN d adds d windows to the master column, kept at 0 or more
def Tall.message(+n: N.Int, +d: N.Rat, +f: N.Rat, m: Msg) -> Maybe<&2, Layout>:
  match m:
    case Shrink{}:
      Some{Tall{n, d, Rat.max0(N.Rat.norm(N.Rat.sub(f, d)))}}
    case Expand{}:
      Some{Tall{n, d, Rat.min1(N.Rat.norm(N.Rat.add(f, d)))}}
    case IncMasterN{k}:
      Some{Tall{Int.max0(N.Int.add(n, k)), d, f}}
    case _:
      None{}

def Mirror.wrap(m: Maybe<&2, Layout>) -> Maybe<&2, Layout>:
  match m:
    case None{}:
      None{}
    case Some{x}:
      Some{Mirror{x}}

def Layout.or(-A: Data, m: Maybe<&2, A>, k: Unit -> Maybe<&2, A>) -> Maybe<&2, A>:
  match m:
    case Some{x}:
      Some{x}
    case None{}:
      k(Unit{})

def Layout.orig(m: Maybe<&2, Layout>, d: Layout) -> Layout:
  match m:
    case None{}:
      d
    case Some{x}:
      x

# Choose's choose: the new Choose with side d2, from the answers ml and mr of
# its two layouts (none: unchanged), and none if neither answered and the
# side stays; a layout switched away from is sent Hide (by hide)
def Choose.choose(d: Side, d2: Side, l: Layout, r: Layout, ml: Maybe<&2, Layout>, mr: Maybe<&2, Layout>, hide: Layout -> Layout) -> Maybe<&2, Layout>:
  match d d2 ml mr:
    case CL{} CL{} None{} None{}:
      None{}
    case CR{} CR{} None{} None{}:
      None{}
    case CL{} CR{} _ _:
      Some{Choose{CR{}, hide(Layout.orig(ml, l)), Layout.orig(mr, r)}}
    case CR{} CL{} _ _:
      Some{Choose{CL{}, Layout.orig(ml, l), hide(Layout.orig(mr, r))}}
    case _ _ _ _:
      Some{Choose{d2, Layout.orig(ml, l), Layout.orig(mr, r)}}

def Choose.jump(+desc: String, +side: Side, +l: Layout, +r: Layout, +ml: Maybe<&2, Layout>, +mr: Maybe<&2, Layout>) -> Side:
  Bool.pick(Side, String.eq(desc, Layout.description(Layout.orig(ml, l))), CL{}, Bool.pick(Side, String.eq(desc, Layout.description(Layout.orig(mr, r))), CR{}, side))

def Side.pickL(s: Side, m: Unit -> Maybe<&2, Layout>) -> Maybe<&2, Layout>:
  match s:
    case CL{}:
      m(Unit{})
    case CR{}:
      None{}

def Side.pickR(s: Side, m: Unit -> Maybe<&2, Layout>) -> Maybe<&2, Layout>:
  match s:
    case CL{}:
      None{}
    case CR{}:
      m(Unit{})

def Choose.nnw.l(+a: Layout, +b: Layout, ml: Maybe<&2, Layout>, fb: Unit -> Maybe<&2, Layout>, hide: Layout -> Layout) -> Maybe<&2, Layout>:
  match ml:
    case Some{x}:
      Choose.choose(CL{}, CL{}, a, b, Some{x}, None{}, hide)
    case None{}:
      Choose.choose(CL{}, CR{}, a, b, None{}, fb(Unit{}), hide)

# Choose's NextNoWrap: on the left, the left layout's next, else the right
# one's first; on the right, the right one's next
def Choose.nnw(side: Side, +a: Layout, +b: Layout, la: Unit -> Maybe<&2, Layout>, fb: Unit -> Maybe<&2, Layout>, nb: Unit -> Maybe<&2, Layout>, hide: Layout -> Layout) -> Maybe<&2, Layout>:
  match side:
    case CL{}:
      Choose.nnw.l(a, b, la(Unit{}), fb, hide)
    case CR{}:
      Choose.choose(CR{}, CR{}, a, b, None{}, nb(Unit{}), hide)

# hide x: x sent Hide, x itself if it does not answer
def Layout.hideWith(+x: Layout, h: Layout -> Maybe<&2, Layout>) -> Layout:
  Layout.orig(h(x), x)

# handleMessage, fuel counted down (see the header)
def Layout.handle(fuel: Nat, l: Layout, +m: Msg) -> Maybe<&2, Layout>:
  match fuel l:
    case 0n _:
      None{}
    case 1n+k Full{}:
      None{}
    case 1n+k Tall{n, d, f}:
      Tall.message(n, d, f, m)
    case 1n+k Mirror{x}:
      Mirror.wrap(Layout.handle(k, x, m))
    case 1n+k Choose{+side, +a, +b}:
      match m:
        case NextLayout{}:
          +j = k
          Layout.or(Layout, Layout.handle(j, Choose{side, a, b}, NextNoWrap{}), _ => Layout.handle(j, Choose{side, a, b}, FirstLayout{}))
        case NextNoWrap{}:
          +j = k
          Choose.nnw(side, a, b, _ => Layout.handle(j, a, NextNoWrap{}), _ => Layout.handle(j, b, FirstLayout{}), _ => Layout.handle(j, b, NextNoWrap{}), x => Layout.hideWith(x, y => Layout.handle(j, y, Hide{})))
        case FirstLayout{}:
          +j = k
          Choose.choose(side, CL{}, a, b, Layout.handle(j, a, FirstLayout{}), None{}, x => Layout.hideWith(x, y => Layout.handle(j, y, Hide{})))
        case ReleaseResources{}:
          +j = k
          Choose.choose(side, side, a, b, Layout.handle(j, a, ReleaseResources{}), Layout.handle(j, b, ReleaseResources{}), x => Layout.hideWith(x, y => Layout.handle(j, y, Hide{})))
        case JumpToLayout{+desc}:
          +j = k
          +ml = Layout.handle(j, a, JumpToLayout{desc})
          +mr = Layout.handle(j, b, JumpToLayout{desc})
          Choose.choose(side, Choose.jump(desc, side, a, b, ml, mr), a, b, ml, mr, x => Layout.hideWith(x, y => Layout.handle(j, y, Hide{})))
        case _:
          +j = k
          Choose.choose(side, side, a, b, Side.pickL(side, _ => Layout.handle(j, a, m)), Side.pickR(side, _ => Layout.handle(j, b, m)), x => Layout.hideWith(x, y => Layout.handle(j, y, Hide{})))

# handleMessage l m: the layout after m, none if l does not answer m
def handleMessage(+l: Layout, m: Msg) -> Maybe<&2, Layout>:
  Layout.handle(1n+1n+Nat.add(Layout.size(l), Layout.size(l)), l, m)
