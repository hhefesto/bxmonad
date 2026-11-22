# XMonad.StackSet in Bend: xmonad's model of the windows, the workspaces and
# the screens, and its pure operations on them.
#
# What it means. A Stack a is a nonempty list with one element in focus:
# focus, the elements above it (up, nearest first) and below it (down).
# Its meaning is the list integrate(s) = reverse(up) ++ [focus] ++ down
# with a position in it. A Workspace is a tag, a layout and a Stack or none
# (no windows). A Screen is a workspace shown on a physical screen (its id
# and details). A StackSet is the screen in focus (current), the other
# screens (visible), the workspaces shown nowhere (hidden), and the
# floating windows' places. Every operation here is a function of those
# values, as XMonad.StackSet's is of its own; the laws (PROPOSED.bend,
# proved in PROOF.bend) say which properties hold, and tests/diff.sh checks
# the answers against XMonad.StackSet's own.
#
# Haskell's classes become templates: a function that Haskell gives Eq a
# takes ~eqA: A -> A -> Bool, and one given Ord a takes ~cmpA: A -> A -> Cmp
# (closed functions, so each is inlined where it is used). A Haskell lambda
# that captures local values becomes a template taking those values as one
# more argument (~f: K -> X -> Y with +k: K): a Bend closure may run only
# once, a template as often as needed.
#
# Where this differs from XMonad.StackSet:
# - new answers Maybe: None where Haskell's calls error ("non-positive
#   argument to StackSet.new"). Screen ids are Nat (Haskell's ScreenId is an
#   Int newtype counted from 0 by new).
# - floating is a list of (window, place) in ascending order of the window
#   (by ~cmpA), each window once: Data.Map's meaning, so two equal maps are
#   one term.
# - focusWindow's `until` is bounded by the number of windows in the current
#   stack plus one (Bend demands that every loop ends). It reaches the
#   window within that many steps whenever Haskell's loop ends at all.
# - A RationalRect's four numbers are Rats (Num.bend).

import Base
import ./Num.bend as N

# Types ------------------------------------------------------------------------

type Stack<-A: Data> is Data:
  Stack{focus: A, up: List<&2, A>, down: List<&2, A>}

type Workspace<-I: Data, -L: Data, -A: Data> is Data:
  Workspace{tag: I, layout: L, stack: Maybe<&2, Stack<A>>}

type Screen<-I: Data, -L: Data, -A: Data, -S: Data, -D: Data> is Data:
  Screen{workspace: Workspace<I, L, A>, screen: S, detail: D}

# A floating window's place: its x, y, width and height as fractions of its
# screen's
type RationalRect is Data:
  RationalRect{x: N.Rat, y: N.Rat, w: N.Rat, h: N.Rat}

type Float<-A: Data> is Data:
  Float{win: A, rect: RationalRect}

type StackSet<-I: Data, -L: Data, -A: Data, -S: Data, -D: Data> is Data:
  StackSet{current: Screen<I, L, A, S, D>, visible: List<&2, Screen<I, L, A, S, D>>, hidden: List<&2, Workspace<I, L, A>>, floating: List<&2, Float<A>>}

# Fields -----------------------------------------------------------------------

def Stack.focus(-A: Data, s: Stack<A>) -> A:
  match s:
    case Stack{f, _, _}:
      f

def Workspace.tag(-I: Data, -L: Data, -A: Data, w: Workspace<I, L, A>) -> I:
  match w:
    case Workspace{t, _, _}:
      t

def Workspace.layout(-I: Data, -L: Data, -A: Data, w: Workspace<I, L, A>) -> L:
  match w:
    case Workspace{_, l, _}:
      l

def Workspace.stack(-I: Data, -L: Data, -A: Data, w: Workspace<I, L, A>) -> Maybe<&2, Stack<A>>:
  match w:
    case Workspace{_, _, s}:
      s

def Screen.workspace(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, c: Screen<I, L, A, S, D>) -> Workspace<I, L, A>:
  match c:
    case Screen{w, _, _}:
      w

def Screen.screen(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, c: Screen<I, L, A, S, D>) -> S:
  match c:
    case Screen{_, s, _}:
      s

def current(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> Screen<I, L, A, S, D>:
  match s:
    case StackSet{c, _, _, _}:
      c

def visible(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, Screen<I, L, A, S, D>>:
  match s:
    case StackSet{_, v, _, _}:
      v

def hidden(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, Workspace<I, L, A>>:
  match s:
    case StackSet{_, _, h, _}:
      h

def floating(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, Float<A>>:
  match s:
    case StackSet{_, _, _, f}:
      f

# Stacks -----------------------------------------------------------------------

# integrate: the stack as a list, top to bottom
def Stack.integrate(-A: Data, s: Stack<A>) -> List<&2, A>:
  match s:
    case Stack{x, l, r}:
      List.append(&2, A, List.reverse(&2, A, l), x <> r)

# integrate': no stack is no windows
def Stack.integrate.maybe(-A: Data, m: Maybe<&2, Stack<A>>) -> List<&2, A>:
  match m:
    case None{}:
      Nil{}
    case Some{s}:
      Stack.integrate(A, s)

# differentiate: a list as a stack focused on its first element
def Stack.differentiate(-A: Data, xs: List<&2, A>) -> Maybe<&2, Stack<A>>:
  match xs:
    case Nil{}:
      None{}
    case x <> rest:
      Some{Stack{x, Nil{}, rest}}

def Stack.reverse(-A: Data, s: Stack<A>) -> Stack<A>:
  match s:
    case Stack{t, ls, rs}:
      Stack{t, rs, ls}

# the stack whose list, top to bottom, is reverse(xs): reverse(t : rs) with
# its first element in focus (Haskell's NE.reverse; xs is never empty
# where it is called, and t stands in for an empty one)
def Stack.top(-A: Data, xs: List<&2, A>, t: A) -> Stack<A>:
  match xs:
    case Nil{}:
      Stack{t, Nil{}, Nil{}}
    case x <> rest:
      Stack{x, rest, Nil{}}

# focusUp': the focus one up, wrapping from the top to the bottom
def Stack.focusUp(-A: Data, s: Stack<A>) -> Stack<A>:
  match s:
    case Stack{t, l <> ls, rs}:
      Stack{l, ls, t <> rs}
    case Stack{+t, Nil{}, rs}:
      Stack.top(A, List.reverse(&2, A, t <> rs), t)

# focusDown': the focus one down, wrapping from the bottom to the top
def Stack.focusDown(-A: Data, s: Stack<A>) -> Stack<A>:
  Stack.reverse(A, Stack.focusUp(A, Stack.reverse(A, s)))

# swapUp': the focused element one up, from the top to the bottom
def Stack.swapUp(-A: Data, s: Stack<A>) -> Stack<A>:
  match s:
    case Stack{t, l <> ls, rs}:
      Stack{t, ls, l <> rs}
    case Stack{t, Nil{}, rs}:
      Stack{t, List.reverse(&2, A, rs), Nil{}}

def Stack.swapDown(-A: Data, s: Stack<A>) -> Stack<A>:
  Stack.reverse(A, Stack.swapUp(A, Stack.reverse(A, s)))

# the elements of xs for which p(k, x)
def List.keep(~A: Data, ~K: Data, ~p: K -> A -> Bool, +k: K, xs: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> rest:
      List.filter.put(A, x, List.keep(~A, ~K, ~p, k, rest), p(k, x))

# filter p's stack: the focus the first kept element at or below it, else the
# nearest kept one above; none if nothing is kept
def Stack.filter.up(-A: Data, ls: List<&2, A>) -> Maybe<&2, Stack<A>>:
  match ls:
    case Nil{}:
      None{}
    case f <> rest:
      Some{Stack{f, rest, Nil{}}}

def Stack.filter.down(-A: Data, rs: List<&2, A>, ls: List<&2, A>) -> Maybe<&2, Stack<A>>:
  match rs:
    case f <> rest:
      Some{Stack{f, ls, rest}}
    case Nil{}:
      Stack.filter.up(A, ls)

def Stack.filter(~A: Data, ~K: Data, ~p: K -> A -> Bool, +k: K, s: Stack<A>) -> Maybe<&2, Stack<A>>:
  match s:
    case Stack{f, ls, rs}:
      Stack.filter.down(A, List.keep(~A, ~K, ~p, k, f <> rs), List.keep(~A, ~K, ~p, k, ls))

# x /= w, as filter (/= w) asks
def Stack.ne(~A: Data, ~eqA: A -> A -> Bool, w: A, x: A) -> Bool:
  Bool.not(eqA(x, w))

# the stack without w (the stack >>= filter (/= w) of delete')
def Stack.remove(~A: Data, ~eqA: A -> A -> Bool, +w: A, m: Maybe<&2, Stack<A>>) -> Maybe<&2, Stack<A>>:
  match m:
    case None{}:
      None{}
    case Some{s}:
      Stack.filter(~A, ~A, ~(w => x => Stack.ne(~A, ~eqA, w, x)), w, s)

# an if: Bend matches only parameters, so the branches are thunks
def Bool.if(-R: Type, c: Bool, t: Unit -> R, e: Unit -> R) -> R:
  match c:
    case True{}:
      t(Unit{})
    case False{}:
      e(Unit{})

# compare's three answers, the branches thunks
def Cmp.case(-R: Type, c: Cmp, lt: Unit -> R, eq: Unit -> R, gt: Unit -> R) -> R:
  match c:
    case LT{}:
      lt(Unit{})
    case EQ{}:
      eq(Unit{})
    case GT{}:
      gt(Unit{})

# == from compare, as Ord's superclass Eq gives it
def Ord.eq(~A: Data, ~cmpA: A -> A -> Cmp, x: A, y: A) -> Bool:
  Cmp.is_eq(cmpA(x, y))

# elem: whether some element of xs is y (Data.List's elem_by: eq x y)
def List.elem(~A: Data, ~eqA: A -> A -> Bool, +y: A, xs: List<&2, A>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case x <> rest:
      Bool.or(eqA(x, y), List.elem(~A, ~eqA, y, rest))

# nub: the first of each run of equal elements, in order (seen: the ones kept)
def List.nub.go(~A: Data, ~eqA: A -> A -> Bool, xs: List<&2, A>, +seen: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> +rest:
      Bool.if(List<&2, A>, List.elem(~A, ~eqA, x, seen), _ => List.nub.go(~A, ~eqA, rest, seen), _ => x <> List.nub.go(~A, ~eqA, rest, x <> seen))

def List.nub(~A: Data, ~eqA: A -> A -> Bool, xs: List<&2, A>) -> List<&2, A>:
  List.nub.go(~A, ~eqA, xs, Nil{})

# delete: xs without its first element equal to y
def List.delete(~A: Data, ~eqA: A -> A -> Bool, +y: A, xs: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> +rest:
      Bool.if(List<&2, A>, eqA(y, x), _ => rest, _ => x <> List.delete(~A, ~eqA, y, rest))

# xs \\ ys: each element of ys deleted from xs once
def List.diff.go(~A: Data, ~eqA: A -> A -> Bool, ys: List<&2, A>, xs: List<&2, A>) -> List<&2, A>:
  match ys:
    case Nil{}:
      xs
    case y <> rest:
      List.diff.go(~A, ~eqA, rest, List.delete(~A, ~eqA, y, xs))

def List.diff(~A: Data, ~eqA: A -> A -> Bool, xs: List<&2, A>, ys: List<&2, A>) -> List<&2, A>:
  List.diff.go(~A, ~eqA, ys, xs)

# The current stack ------------------------------------------------------------

def with.go(-A: Data, -B: Type, m: Maybe<&2, Stack<A>>, dflt: B, f: Stack<A> -> B) -> B:
  match m:
    case None{}:
      dflt
    case Some{x}:
      f(x)

# with: f of the current workspace's stack, dflt if it has none
def with(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, -B: Type, dflt: B, f: Stack<A> -> B, s: StackSet<I, L, A, S, D>) -> B:
  with.go(A, B, Workspace.stack(I, L, A, Screen.workspace(I, L, A, S, D, current(I, L, A, S, D, s))), dflt, f)

# modify: the current stack replaced by with(d, f, s)
def modify(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, d: Maybe<&2, Stack<A>>, f: Stack<A> -> Maybe<&2, Stack<A>>, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match s:
    case StackSet{Screen{Workspace{t, l, st}, sc, sd}, v, h, fl}:
      StackSet{Screen{Workspace{t, l, with.go(A, Maybe<&2, Stack<A>>, st, d, f)}, sc, sd}, v, h, fl}

# modify': f on the current stack, if there is one
def modify_(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, f: Stack<A> -> Stack<A>, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify(I, L, A, S, D, None{}, x => Some{f(x)}, s)

# peek: the focused window
def peek(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> Maybe<&2, A>:
  with(I, L, A, S, D, Maybe<&2, A>, None{}, x => Some{Stack.focus(A, x)}, s)

# index: the current workspace's windows, top to bottom
def index(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, A>:
  with(I, L, A, S, D, List<&2, A>, Nil{}, x => Stack.integrate(A, x), s)

def focusUp(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.focusUp(A, x), s)

def focusDown(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.focusDown(A, x), s)

def swapUp(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.swapUp(A, x), s)

def swapDown(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.swapDown(A, x), s)

# the stack whose top is the last of xs (NE.reverse (l :| ls) = x :| rest):
# focus t, nothing above, rest ++ x : rs below (swapMaster)
def Stack.swapMaster.go(-A: Data, xs: List<&2, A>, t: A, rs: List<&2, A>) -> Stack<A>:
  match xs:
    case x <> rest:
      Stack{t, Nil{}, List.append(&2, A, rest, x <> rs)}
    case Nil{}:
      Stack{t, Nil{}, rs}

# swapMaster's change: the focus swapped with the top
def Stack.swapMaster(-A: Data, c: Stack<A>) -> Stack<A>:
  match c:
    case Stack{t, Nil{}, rs}:
      Stack{t, Nil{}, rs}
    case Stack{t, l <> ls, rs}:
      Stack.swapMaster.go(A, List.reverse(&2, A, l <> ls), t, rs)

# shiftMaster's change: the focus moved to the top, the rest in order
def Stack.shiftMaster(-A: Data, c: Stack<A>) -> Stack<A>:
  match c:
    case Stack{t, Nil{}, rs}:
      Stack{t, Nil{}, rs}
    case Stack{t, l <> ls, rs}:
      Stack{t, Nil{}, List.append(&2, A, List.reverse(&2, A, l <> ls), rs)}

def Stack.focusMaster.go(-A: Data, xs: List<&2, A>, +t: A, rs: List<&2, A>) -> Stack<A>:
  match xs:
    case x <> rest:
      Stack{x, Nil{}, List.append(&2, A, rest, t <> rs)}
    case Nil{}:
      Stack{t, Nil{}, rs}

# focusMaster's change: the focus moved to the top window
def Stack.focusMaster(-A: Data, c: Stack<A>) -> Stack<A>:
  match c:
    case Stack{t, Nil{}, rs}:
      Stack{t, Nil{}, rs}
    case Stack{t, l <> ls, rs}:
      Stack.focusMaster.go(A, List.reverse(&2, A, l <> ls), t, rs)

def swapMaster(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.swapMaster(A, x), s)

def shiftMaster(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.shiftMaster(A, x), s)

def focusMaster(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  modify_(I, L, A, S, D, x => Stack.focusMaster(A, x), s)

# Screens and workspaces -------------------------------------------------------

def screens(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, Screen<I, L, A, S, D>>:
  match s:
    case StackSet{c, v, _, _}:
      c <> v

# the workspaces the screens show, then hs
def Screen.workspaces(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, xs: List<&2, Screen<I, L, A, S, D>>, hs: List<&2, Workspace<I, L, A>>) -> List<&2, Workspace<I, L, A>>:
  match xs:
    case Nil{}:
      hs
    case Screen{w, _, _} <> rest:
      w <> Screen.workspaces(I, L, A, S, D, rest, hs)

# workspaces: the current one, the visible ones, the hidden ones
def workspaces(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, Workspace<I, L, A>>:
  match s:
    case StackSet{Screen{w, _, _}, v, h, _}:
      w <> Screen.workspaces(I, L, A, S, D, v, h)

def currentTag(-I: Data, -L: Data, -A: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> I:
  Workspace.tag(I, L, A, Screen.workspace(I, L, A, S, D, current(I, L, A, S, D, s)))

# every workspace's windows, in order
def Workspace.windows(-I: Data, -L: Data, -A: Data, ws: List<&2, Workspace<I, L, A>>) -> List<&2, A>:
  match ws:
    case Nil{}:
      Nil{}
    case Workspace{_, _, st} <> rest:
      List.append(&2, A, Stack.integrate.maybe(A, st), Workspace.windows(I, L, A, rest))

# allWindows: every window, each once
def allWindows(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, s: StackSet<I, L, A, S, D>) -> List<&2, A>:
  List.nub(~A, ~eqA, Workspace.windows(I, L, A, workspaces(I, L, A, S, D, s)))

# whether some workspace is tagged t
def Workspace.hasTag(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, +t: I, ws: List<&2, Workspace<I, L, A>>) -> Bool:
  match ws:
    case Nil{}:
      False{}
    case Workspace{u, _, _} <> rest:
      Bool.or(eqI(u, t), Workspace.hasTag(~I, ~eqI, L, A, t, rest))

def tagMember(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, -S: Data, -D: Data, +t: I, s: StackSet<I, L, A, S, D>) -> Bool:
  Workspace.hasTag(~I, ~eqI, L, A, t, workspaces(I, L, A, S, D, s))

# the first screen showing a workspace tagged i
def Screen.findTag(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, -S: Data, -D: Data, +i: I, xs: List<&2, Screen<I, L, A, S, D>>) -> Maybe<&2, Screen<I, L, A, S, D>>:
  match xs:
    case Nil{}:
      None{}
    case +x <> rest:
      List.find.if(Screen<I, L, A, S, D>, x, _ => Screen.findTag(~I, ~eqI, L, A, S, D, i, rest), eqI(i, Workspace.tag(I, L, A, Screen.workspace(I, L, A, S, D, x))))

# the first workspace tagged i
def Workspace.find(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, +i: I, xs: List<&2, Workspace<I, L, A>>) -> Maybe<&2, Workspace<I, L, A>>:
  match xs:
    case Nil{}:
      None{}
    case +x <> rest:
      List.find.if(Workspace<I, L, A>, x, _ => Workspace.find(~I, ~eqI, L, A, i, rest), eqI(i, Workspace.tag(I, L, A, x)))

# deleteBy (equating screen) x: the first screen whose id is sc taken out
def Screen.delete(~S: Data, ~eqS: S -> S -> Bool, -I: Data, -L: Data, -A: Data, -D: Data, +sc: S, xs: List<&2, Screen<I, L, A, S, D>>) -> List<&2, Screen<I, L, A, S, D>>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> +rest:
      Bool.if(List<&2, Screen<I, L, A, S, D>>, eqS(sc, Screen.screen(I, L, A, S, D, x)), _ => rest, _ => x <> Screen.delete(~S, ~eqS, I, L, A, D, sc, rest))

# deleteBy (equating tag) x: the first workspace tagged t taken out
def Workspace.delete(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, +t: I, xs: List<&2, Workspace<I, L, A>>) -> List<&2, Workspace<I, L, A>>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> +rest:
      Bool.if(List<&2, Workspace<I, L, A>>, eqI(t, Workspace.tag(I, L, A, x)), _ => rest, _ => x <> Workspace.delete(~I, ~eqI, L, A, t, rest))

# the screens whose workspace is not tagged w (filter (not . wTag . workspace))
def Screen.dropTag(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, -S: Data, -D: Data, +w: I, xs: List<&2, Screen<I, L, A, S, D>>) -> List<&2, Screen<I, L, A, S, D>>:
  match xs:
    case Nil{}:
      Nil{}
    case +x <> rest:
      List.filter.put(Screen<I, L, A, S, D>, x, Screen.dropTag(~I, ~eqI, L, A, S, D, w, rest), Bool.not(eqI(w, Workspace.tag(I, L, A, Screen.workspace(I, L, A, S, D, x)))))

# whether some workspace is tagged w (any wTag)
def Workspace.anyTag(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, +w: I, xs: List<&2, Workspace<I, L, A>>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case x <> rest:
      Bool.or(eqI(w, Workspace.tag(I, L, A, x)), Workspace.anyTag(~I, ~eqI, L, A, w, rest))

# Viewing ----------------------------------------------------------------------

def view.hid(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, -S: Data, -D: Data, m: Maybe<&2, Workspace<I, L, A>>, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match m:
    case None{}:
      s
    case Some{+x}:
      match s:
        case StackSet{Screen{w, sc, sd}, v, h, f}:
          StackSet{Screen{x, sc, sd}, v, w <> Workspace.delete(~I, ~eqI, L, A, Workspace.tag(I, L, A, x), h), f}

def view.vis(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, -L: Data, -A: Data, -D: Data, m: Maybe<&2, Screen<I, L, A, S, D>>, +i: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match m:
    case None{}:
      view.hid(~I, ~eqI, L, A, S, D, Workspace.find(~I, ~eqI, L, A, i, hidden(I, L, A, S, D, s)), s)
    case Some{+x}:
      match s:
        case StackSet{c, v, h, f}:
          StackSet{x, c <> Screen.delete(~S, ~eqS, I, L, A, D, Screen.screen(I, L, A, S, D, x), v), h, f}

def view.cur(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, -L: Data, -A: Data, -D: Data, c: Bool, +i: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match c:
    case True{}:
      s
    case False{}:
      view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, Screen.findTag(~I, ~eqI, L, A, S, D, i, visible(I, L, A, S, D, s)), i, s)

# view i: the workspace tagged i in focus: already current, else swapped in
# from the visible screens (its screen in focus), else from the hidden
# workspaces (shown on the current screen); a tag no workspace has changes
# nothing
def view(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, -L: Data, -A: Data, -D: Data, +i: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  view.cur(~I, ~eqI, ~S, ~eqS, L, A, D, eqI(i, currentTag(I, L, A, S, D, s)), i, s)

def greedyView.vis(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, -S: Data, -D: Data, m: Maybe<&2, Screen<I, L, A, S, D>>, +w: I, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match m:
    case None{}:
      s
    case Some{Screen{sw, ssc, ssd}}:
      match s:
        case StackSet{Screen{cw, sc, sd}, v, h, f}:
          StackSet{Screen{sw, sc, sd}, Screen{cw, ssc, ssd} <> Screen.dropTag(~I, ~eqI, L, A, S, D, w, v), h, f}

def greedyView.hid(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, -L: Data, -A: Data, -D: Data, c: Bool, +w: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match c:
    case True{}:
      view(~I, ~eqI, ~S, ~eqS, L, A, D, w, s)
    case False{}:
      greedyView.vis(~I, ~eqI, L, A, S, D, Screen.findTag(~I, ~eqI, L, A, S, D, w, visible(I, L, A, S, D, s)), w, s)

# greedyView w: as view, but a workspace on another screen is swapped onto
# the current screen, the other screen getting the current workspace
def greedyView(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, -L: Data, -A: Data, -D: Data, +w: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  greedyView.hid(~I, ~eqI, ~S, ~eqS, L, A, D, Workspace.anyTag(~I, ~eqI, L, A, w, hidden(I, L, A, S, D, s)), w, s)

def Screen.lookup(~S: Data, ~eqS: S -> S -> Bool, -I: Data, -L: Data, -A: Data, -D: Data, +sc: S, xs: List<&2, Screen<I, L, A, S, D>>) -> Maybe<&2, I>:
  match xs:
    case Nil{}:
      None{}
    case Screen{w, s0, _} <> rest:
      Bool.if(Maybe<&2, I>, eqS(s0, sc), _ => Some{Workspace.tag(I, L, A, w)}, _ => Screen.lookup(~S, ~eqS, I, L, A, D, sc, rest))

# lookupWorkspace sc: the tag of the workspace on screen sc, if any
def lookupWorkspace(~S: Data, ~eqS: S -> S -> Bool, -I: Data, -L: Data, -A: Data, -D: Data, +sc: S, s: StackSet<I, L, A, S, D>) -> Maybe<&2, I>:
  Screen.lookup(~S, ~eqS, I, L, A, D, sc, screens(I, L, A, S, D, s))

# Windows ----------------------------------------------------------------------

# whether a stack (or none) holds x (has x st = x `elem` integrate' st)
def Stack.has(~A: Data, ~eqA: A -> A -> Bool, +x: A, m: Maybe<&2, Stack<A>>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{Stack{t, l, r}}:
      List.elem(~A, ~eqA, x, t <> List.append(&2, A, l, r))

def Workspace.findWin(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, +a: A, ws: List<&2, Workspace<I, L, A>>) -> Maybe<&2, I>:
  match ws:
    case Nil{}:
      None{}
    case Workspace{t, _, st} <> rest:
      Bool.if(Maybe<&2, I>, Stack.has(~A, ~eqA, a, st), _ => Some{t}, _ => Workspace.findWin(~A, ~eqA, I, L, a, rest))

# findTag a: the tag of the first workspace holding a
def findTag(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, +a: A, s: StackSet<I, L, A, S, D>) -> Maybe<&2, I>:
  Workspace.findWin(~A, ~eqA, I, L, a, workspaces(I, L, A, S, D, s))

def member(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, +a: A, s: StackSet<I, L, A, S, D>) -> Bool:
  Maybe.is_some(&2, I, findTag(~A, ~eqA, I, L, S, D, a, s))

def insertUp.ins(-A: Data, a: A, c: Stack<A>) -> Maybe<&2, Stack<A>>:
  match c:
    case Stack{t, l, r}:
      Some{Stack{a, l, t <> r}}

# insertUp a: a new window above the focus, in focus; a window already in
# the set changes nothing
def insertUp(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, +a: A, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  Bool.if(StackSet<I, L, A, S, D>, member(~A, ~eqA, I, L, S, D, a, s), _ => s, _ => modify(I, L, A, S, D, Some{Stack{a, Nil{}, Nil{}}}, x => insertUp.ins(A, a, x), s))

def Workspace.remove(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, +w: A, x: Workspace<I, L, A>) -> Workspace<I, L, A>:
  match x:
    case Workspace{t, l, st}:
      Workspace{t, l, Stack.remove(~A, ~eqA, w, st)}

def Workspace.removeAll(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, +w: A, xs: List<&2, Workspace<I, L, A>>) -> List<&2, Workspace<I, L, A>>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      Workspace.remove(~A, ~eqA, I, L, w, x) <> Workspace.removeAll(~A, ~eqA, I, L, w, rest)

def Screen.removeAll(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, +w: A, xs: List<&2, Screen<I, L, A, S, D>>) -> List<&2, Screen<I, L, A, S, D>>:
  match xs:
    case Nil{}:
      Nil{}
    case Screen{x, sc, sd} <> rest:
      Screen{Workspace.remove(~A, ~eqA, I, L, w, x), sc, sd} <> Screen.removeAll(~A, ~eqA, I, L, S, D, w, rest)

# delete' w: w out of every workspace (the floating places kept)
def delete_(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, +w: A, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match s:
    case StackSet{Screen{x, sc, sd}, v, h, f}:
      StackSet{Screen{Workspace.remove(~A, ~eqA, I, L, w, x), sc, sd}, Screen.removeAll(~A, ~eqA, I, L, S, D, w, v), Workspace.removeAll(~A, ~eqA, I, L, w, h), f}

# Floating ---------------------------------------------------------------------

# Data.Map's insert, on a list in ascending order of the key
def Float.insert(~A: Data, ~cmpA: A -> A -> Cmp, +w: A, +r: RationalRect, xs: List<&2, Float<A>>) -> List<&2, Float<A>>:
  match xs:
    case Nil{}:
      [Float{w, r}]
    case Float{+k, +v} <> +rest:
      Cmp.case(List<&2, Float<A>>, cmpA(w, k), _ => Float{w, r} <> Float{k, v} <> rest, _ => Float{w, r} <> rest, _ => Float{k, v} <> Float.insert(~A, ~cmpA, w, r, rest))

# Data.Map's delete
def Float.delete(~A: Data, ~cmpA: A -> A -> Cmp, +w: A, xs: List<&2, Float<A>>) -> List<&2, Float<A>>:
  match xs:
    case Nil{}:
      Nil{}
    case Float{+k, +v} <> +rest:
      Cmp.case(List<&2, Float<A>>, cmpA(w, k), _ => Float{k, v} <> rest, _ => rest, _ => Float{k, v} <> Float.delete(~A, ~cmpA, w, rest))

# Data.Map's lookup
def Float.lookup(~A: Data, ~cmpA: A -> A -> Cmp, +w: A, xs: List<&2, Float<A>>) -> Maybe<&2, RationalRect>:
  match xs:
    case Nil{}:
      None{}
    case Float{+k, +v} <> rest:
      Cmp.case(Maybe<&2, RationalRect>, cmpA(w, k), _ => None{}, _ => Some{v}, _ => Float.lookup(~A, ~cmpA, w, rest))

# float w r: w floats at r
def float(~A: Data, ~cmpA: A -> A -> Cmp, -I: Data, -L: Data, -S: Data, -D: Data, +w: A, +r: RationalRect, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match s:
    case StackSet{c, v, h, f}:
      StackSet{c, v, h, Float.insert(~A, ~cmpA, w, r, f)}

# sink w: w floats no more
def sink(~A: Data, ~cmpA: A -> A -> Cmp, -I: Data, -L: Data, -S: Data, -D: Data, +w: A, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match s:
    case StackSet{c, v, h, f}:
      StackSet{c, v, h, Float.delete(~A, ~cmpA, w, f)}

# delete w: w out of the set, floating or not (Ord a: == is compare's EQ)
def delete(~A: Data, ~cmpA: A -> A -> Cmp, -I: Data, -L: Data, -S: Data, -D: Data, +w: A, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  sink(~A, ~cmpA, I, L, S, D, w, delete_(~A, ~(x => y => Ord.eq(~A, ~cmpA, x, y)), I, L, S, D, w, s))

# Focus by window --------------------------------------------------------------

# whether m is Just w (Just w == m)
def Maybe.isJust(~A: Data, ~eqA: A -> A -> Bool, +w: A, m: Maybe<&2, A>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{x}:
      eqA(w, x)

# until ((Just w ==) . peek) focusUp, at most fuel steps
def focusWindow.until(~A: Data, ~eqA: A -> A -> Bool, -I: Data, -L: Data, -S: Data, -D: Data, fuel: Nat, +w: A, +x: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match fuel:
    case 0n:
      x
    case 1n+k:
      Bool.if(StackSet<I, L, A, S, D>, Maybe.isJust(~A, ~eqA, w, peek(I, L, A, S, D, x)), _ => x, _ => focusWindow.until(~A, ~eqA, I, L, S, D, k, w, focusUp(I, L, A, S, D, x)))

def focusWindow.go(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, ~A: Data, ~eqA: A -> A -> Bool, -L: Data, -D: Data, m: Maybe<&2, I>, +w: A, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match m:
    case None{}:
      s
    case Some{n}:
      +v = view(~I, ~eqI, ~S, ~eqS, L, A, D, n, s)
      focusWindow.until(~A, ~eqA, I, L, S, D, 1n+List.length(&2, A, index(I, L, A, S, D, v)), w, v)

# focusWindow w: w's workspace in view and w in focus; a window not in the
# set changes nothing
def focusWindow(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, ~A: Data, ~eqA: A -> A -> Bool, -L: Data, -D: Data, +w: A, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  Bool.if(StackSet<I, L, A, S, D>, Maybe.isJust(~A, ~eqA, w, peek(I, L, A, S, D, s)), _ => s, _ => focusWindow.go(~I, ~eqI, ~S, ~eqS, ~A, ~eqA, L, D, findTag(~A, ~eqA, I, L, S, D, w, s), w, s))

# Tags and layouts -------------------------------------------------------------

def Workspace.mapAll(~I: Data, ~L: Data, ~A: Data, ~K: Data, ~f: K -> Workspace<I, L, A> -> Workspace<I, L, A>, +k: K, xs: List<&2, Workspace<I, L, A>>) -> List<&2, Workspace<I, L, A>>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      f(k, x) <> Workspace.mapAll(~I, ~L, ~A, ~K, ~f, k, rest)

def Screen.mapAll(~I: Data, ~L: Data, ~A: Data, ~K: Data, ~f: K -> Workspace<I, L, A> -> Workspace<I, L, A>, -S: Data, -D: Data, +k: K, xs: List<&2, Screen<I, L, A, S, D>>) -> List<&2, Screen<I, L, A, S, D>>:
  match xs:
    case Nil{}:
      Nil{}
    case Screen{w, sc, sd} <> rest:
      Screen{f(k, w), sc, sd} <> Screen.mapAll(~I, ~L, ~A, ~K, ~f, S, D, k, rest)

# mapWorkspace f, f taking k besides the workspace (Haskell's f closed over k)
def mapWorkspace(~I: Data, ~L: Data, ~A: Data, ~K: Data, ~f: K -> Workspace<I, L, A> -> Workspace<I, L, A>, -S: Data, -D: Data, +k: K, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match s:
    case StackSet{Screen{w, sc, sd}, v, h, fl}:
      StackSet{Screen{f(k, w), sc, sd}, Screen.mapAll(~I, ~L, ~A, ~K, ~f, S, D, k, v), Workspace.mapAll(~I, ~L, ~A, ~K, ~f, k, h), fl}

# a renaming: old to new
type Rename<-I: Data> is Data:
  Rename{old: I, new: I}

def Workspace.rename(~I: Data, ~eqI: I -> I -> Bool, -L: Data, -A: Data, r: Rename<I>, w: Workspace<I, L, A>) -> Workspace<I, L, A>:
  match r w:
    case Rename{o, n} Workspace{+t, l, st}:
      Workspace{Bool.pick(I, eqI(t, o), n, t), l, st}

# renameTag o n: every workspace tagged o tagged n instead
def renameTag(~I: Data, ~eqI: I -> I -> Bool, ~L: Data, ~A: Data, -S: Data, -D: Data, +o: I, +n: I, s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  mapWorkspace(~I, ~L, ~A, ~Rename<I>, ~(r => w => Workspace.rename(~I, ~eqI, L, A, r, w)), S, D, Rename{o, n}, s)

def Workspace.relayout(~L: Data, ~L2: Data, ~K: Data, ~f: K -> L -> L2, -I: Data, -A: Data, +k: K, w: Workspace<I, L, A>) -> Workspace<I, L2, A>:
  match w:
    case Workspace{t, l, st}:
      Workspace{t, f(k, l), st}

def Workspace.relayoutAll(~L: Data, ~L2: Data, ~K: Data, ~f: K -> L -> L2, -I: Data, -A: Data, +k: K, xs: List<&2, Workspace<I, L, A>>) -> List<&2, Workspace<I, L2, A>>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      Workspace.relayout(~L, ~L2, ~K, ~f, I, A, k, x) <> Workspace.relayoutAll(~L, ~L2, ~K, ~f, I, A, k, rest)

def Screen.relayoutAll(~L: Data, ~L2: Data, ~K: Data, ~f: K -> L -> L2, -I: Data, -A: Data, -S: Data, -D: Data, +k: K, xs: List<&2, Screen<I, L, A, S, D>>) -> List<&2, Screen<I, L2, A, S, D>>:
  match xs:
    case Nil{}:
      Nil{}
    case Screen{w, sc, sd} <> rest:
      Screen{Workspace.relayout(~L, ~L2, ~K, ~f, I, A, k, w), sc, sd} <> Screen.relayoutAll(~L, ~L2, ~K, ~f, I, A, S, D, k, rest)

# mapLayout f, f taking k besides the layout
def mapLayout(~L: Data, ~L2: Data, ~K: Data, ~f: K -> L -> L2, -I: Data, -A: Data, -S: Data, -D: Data, +k: K, s: StackSet<I, L, A, S, D>) -> StackSet<I, L2, A, S, D>:
  match s:
    case StackSet{Screen{w, sc, sd}, v, h, fl}:
      StackSet{Screen{Workspace.relayout(~L, ~L2, ~K, ~f, I, A, k, w), sc, sd}, Screen.relayoutAll(~L, ~L2, ~K, ~f, I, A, S, D, k, v), Workspace.relayoutAll(~L, ~L2, ~K, ~f, I, A, k, h), fl}

def Workspace.tags(-I: Data, -L: Data, -A: Data, xs: List<&2, Workspace<I, L, A>>) -> List<&2, I>:
  match xs:
    case Nil{}:
      Nil{}
    case Workspace{t, _, _} <> rest:
      t <> Workspace.tags(I, L, A, rest)

# what ensureTags does with one wanted tag i: nothing if a workspace has it;
# else the next unwanted tag renamed i, or, with none left, a new hidden
# workspace tagged i
type Et<-I: Data, -L: Data, -A: Data, -S: Data, -D: Data> is Data:
  Et{rn: List<&2, I>, s: StackSet<I, L, A, S, D>}

def ensureTags.new(~I: Data, ~eqI: I -> I -> Bool, ~L: Data, ~A: Data, -S: Data, -D: Data, rn: List<&2, I>, i: I, l: L, s: StackSet<I, L, A, S, D>) -> Et<I, L, A, S, D>:
  match rn:
    case Nil{}:
      match s:
        case StackSet{c, v, h, f}:
          Et{Nil{}, StackSet{c, v, Workspace{i, l, None{}} <> h, f}}
    case r <> rs:
      Et{rs, renameTag(~I, ~eqI, ~L, ~A, S, D, r, i, s)}

def ensureTags.step(~I: Data, ~eqI: I -> I -> Bool, ~L: Data, ~A: Data, -S: Data, -D: Data, hit: Bool, rn: List<&2, I>, i: I, l: L, s: StackSet<I, L, A, S, D>) -> Et<I, L, A, S, D>:
  match hit:
    case True{}:
      Et{rn, s}
    case False{}:
      ensureTags.new(~I, ~eqI, ~L, ~A, S, D, rn, i, l, s)

def ensureTags.go(~I: Data, ~eqI: I -> I -> Bool, ~L: Data, ~A: Data, -S: Data, -D: Data, all: List<&2, I>, +l: L, et: Et<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match all et:
    case Nil{} Et{_, s}:
      s
    case +i <> more Et{rn, +s}:
      ensureTags.go(~I, ~eqI, ~L, ~A, S, D, more, l, ensureTags.step(~I, ~eqI, ~L, ~A, S, D, tagMember(~I, ~eqI, L, A, S, D, i, s), rn, i, l, s))

# ensureTags l allt: a workspace for every tag of allt, by renaming the
# workspaces whose tags allt lacks, then by new hidden ones laid out by l
def ensureTags(~I: Data, ~eqI: I -> I -> Bool, ~L: Data, ~A: Data, -S: Data, -D: Data, +l: L, +allt: List<&2, I>, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  ensureTags.go(~I, ~eqI, ~L, ~A, S, D, allt, l, Et{List.diff(~I, ~eqI, Workspace.tags(I, L, A, workspaces(I, L, A, S, D, s)), allt), s})

# Moving windows between workspaces --------------------------------------------

# onWorkspace n f: f applied with n in view, then the view put back
def onWorkspace(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, -L: Data, -A: Data, -D: Data, +n: I, f: StackSet<I, L, A, S, D> -> StackSet<I, L, A, S, D>, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  view(~I, ~eqI, ~S, ~eqS, L, A, D, currentTag(I, L, A, S, D, s), f(view(~I, ~eqI, ~S, ~eqS, L, A, D, n, s)))

def shiftWin.go(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, ~A: Data, ~eqA: A -> A -> Bool, -L: Data, -D: Data, m: Maybe<&2, I>, +n: I, +w: A, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match m:
    case None{}:
      s
    case Some{+from}:
      Bool.if(StackSet<I, L, A, S, D>, Bool.and(tagMember(~I, ~eqI, L, A, S, D, n, s), Bool.not(eqI(n, from))), _ => onWorkspace(~I, ~eqI, ~S, ~eqS, L, A, D, n, x => insertUp(~A, ~eqA, I, L, S, D, w, x), onWorkspace(~I, ~eqI, ~S, ~eqS, L, A, D, from, x => delete_(~A, ~eqA, I, L, S, D, w, x), s)), _ => s)

# shiftWin n w: w moved to the workspace tagged n (if there is one, and w is
# elsewhere), on top of its stack, in focus there
def shiftWin(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, ~A: Data, ~eqA: A -> A -> Bool, -L: Data, -D: Data, +n: I, +w: A, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  shiftWin.go(~I, ~eqI, ~S, ~eqS, ~A, ~eqA, L, D, findTag(~A, ~eqA, I, L, S, D, w, s), n, w, s)

def shift.go(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, ~A: Data, ~eqA: A -> A -> Bool, -L: Data, -D: Data, m: Maybe<&2, A>, +n: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  match m:
    case None{}:
      s
    case Some{w}:
      shiftWin(~I, ~eqI, ~S, ~eqS, ~A, ~eqA, L, D, n, w, s)

# shift n: the focused window moved to the workspace tagged n
def shift(~I: Data, ~eqI: I -> I -> Bool, ~S: Data, ~eqS: S -> S -> Bool, ~A: Data, ~eqA: A -> A -> Bool, -L: Data, -D: Data, +n: I, +s: StackSet<I, L, A, S, D>) -> StackSet<I, L, A, S, D>:
  shift.go(~I, ~eqI, ~S, ~eqS, ~A, ~eqA, L, D, peek(I, L, A, S, D, s), n, s)

# A new set ----------------------------------------------------------------------

def new.screens(-I: Data, -L: Data, -A: Data, -D: Data, seen: List<&2, I>, +l: L, +n: Nat, ms: List<&2, D>) -> List<&2, Screen<I, L, A, Nat, D>>:
  match seen ms:
    case i <> more m <> mt:
      Screen{Workspace{i, l, None{}}, n, m} <> new.screens(I, L, A, D, more, l, 1n+n, mt)
    case _ _:
      Nil{}

def new.hidden(-I: Data, -L: Data, -A: Data, xs: List<&2, I>, +l: L) -> List<&2, Workspace<I, L, A>>:
  match xs:
    case Nil{}:
      Nil{}
    case i <> rest:
      Workspace{i, l, None{}} <> new.hidden(I, L, A, rest, l)

def new.ok(-I: Data, -L: Data, -A: Data, -D: Data, ok: Bool, +l: L, wid: I, +wids: List<&2, I>, m: D, +ms: List<&2, D>) -> Maybe<&2, StackSet<I, L, A, Nat, D>>:
  match ok:
    case False{}:
      None{}
    case True{}:
      +k = List.length(&2, D, ms)
      Some{StackSet{Screen{Workspace{wid, l, None{}}, 0n, m}, new.screens(I, L, A, D, List.take(&2, I, wids, k), l, 1n, ms), new.hidden(I, L, A, List.drop(&2, I, wids, k), l), Nil{}}}

# new l wids ms: the first tag on the first screen, in focus, the next tags
# on the other screens (ids 1, 2, ...), the rest hidden, all laid out by l;
# None unless there are tags and screens, and no more screens than tags
def new(-I: Data, -L: Data, -A: Data, -D: Data, +l: L, wids: List<&2, I>, ms: List<&2, D>) -> Maybe<&2, StackSet<I, L, A, Nat, D>>:
  match wids ms:
    case wid <> +rest m <> +mt:
      new.ok(I, L, A, D, Nat.is_le(List.length(&2, D, mt), List.length(&2, I, rest)), l, wid, rest, m, mt)
    case _ _:
      None{}

# Stack as a Functor: f on every element
def Stack.map.list(~A: Data, ~B: Data, ~f: A -> B, xs: List<&2, A>) -> List<&2, B>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      f(x) <> Stack.map.list(~A, ~B, ~f, rest)

def Stack.map(~A: Data, ~B: Data, ~f: A -> B, s: Stack<A>) -> Stack<B>:
  match s:
    case Stack{t, l, r}:
      Stack{f(t), Stack.map.list(~A, ~B, ~f, l), Stack.map.list(~A, ~B, ~f, r)}
