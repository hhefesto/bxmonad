# Laws proposed for the StackSet port, for the human to move into a LAWS.bend
# (or reword or drop): PROOF.bend proves them. They are the properties
# xmonad's own test suite (tests/Properties/*.hs) checks on random values with
# QuickCheck, here proved for every value. A law that needs Haskell's Eq or
# Ord to behave says so as a hypothesis (eqA(a, a) is True, say).

import Base
import ./StackSet.bend as W
import ./Num.bend as N
import ./Layout.bend as L
import ./Core.bend as C
import ./Operations.bend as O

# Stacks
# ------

# A stack read the other way round, twice, is the stack.
law stack_reverse_twice:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.reverse(A, W.Stack.reverse(A, s)) == s : W.Stack<A>}

# prop_differentiate: a list made a stack and read back is the list.
law integrate_differentiate:
  for -A: Data
  for xs: List<&2, A>
  {W.Stack.integrate.maybe(A, W.Stack.differentiate(A, xs)) == xs : List<&2, A>}

# prop_focus_left, prop_focus_right: focusUp and focusDown undo each other.
law focusUp_focusDown:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focusUp(A, W.Stack.focusDown(A, s)) == s : W.Stack<A>}

law focusDown_focusUp:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focusDown(A, W.Stack.focusUp(A, s)) == s : W.Stack<A>}

# prop_swap_left, prop_swap_right: swapUp and swapDown undo each other.
law swapUp_swapDown:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.swapUp(A, W.Stack.swapDown(A, s)) == s : W.Stack<A>}

law swapDown_swapUp:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.swapDown(A, W.Stack.swapUp(A, s)) == s : W.Stack<A>}

# prop_swap_left_focus, prop_swap_right_focus, prop_swap_master_focus,
# prop_shift_master_focus: moving the focused window keeps it in focus.
law swapUp_focus:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focus(A, W.Stack.swapUp(A, s)) == W.Stack.focus(A, s) : A}

law swapDown_focus:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focus(A, W.Stack.swapDown(A, s)) == W.Stack.focus(A, s) : A}

law swapMaster_focus:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focus(A, W.Stack.swapMaster(A, s)) == W.Stack.focus(A, s) : A}

law shiftMaster_focus:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focus(A, W.Stack.shiftMaster(A, s)) == W.Stack.focus(A, s) : A}

# focusMaster moves the focus, not the windows (prop_focus_master_master's
# point: the order on screen is the same).
law focusMaster_integrate:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.integrate(A, W.Stack.focusMaster(A, s)) == W.Stack.integrate(A, s) : List<&2, A>}

# prop_focusMaster_idem, prop_shift_master_idempotent, and swapMaster's: once
# the focus is on top, doing it again changes nothing.
law focusMaster_idem:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.focusMaster(A, W.Stack.focusMaster(A, s)) == W.Stack.focusMaster(A, s) : W.Stack<A>}

law shiftMaster_idem:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.shiftMaster(A, W.Stack.shiftMaster(A, s)) == W.Stack.shiftMaster(A, s) : W.Stack<A>}

law swapMaster_idem:
  for -A: Data
  for s: W.Stack<A>
  {W.Stack.swapMaster(A, W.Stack.swapMaster(A, s)) == W.Stack.swapMaster(A, s) : W.Stack<A>}

# prop_laws_Stack (Functor's half): map by the identity changes nothing, and
# a map of a map is the map of the composite.
def ident(-A: Data, x: A) -> A:
  x

def comp(~A: Data, ~B: Data, ~C: Data, ~f: A -> B, ~g: B -> C, x: A) -> C:
  g(f(x))

law stack_map_id:
  for ~A: Data
  for s: W.Stack<A>
  {W.Stack.map(~A, ~A, ~ident(A), s) == s : W.Stack<A>}

law stack_map_comp:
  for ~A: Data
  for ~B: Data
  for ~C: Data
  for ~f: A -> B
  for ~g: B -> C
  for s: W.Stack<A>
  {W.Stack.map(~B, ~C, ~g, W.Stack.map(~A, ~B, ~f, s)) == W.Stack.map(~A, ~C, ~comp(~A, ~B, ~C, ~f, ~g), s) : W.Stack<C>}

# The set
# -------
#
# The operations on the current stack, lifted to the set by modify', keep
# their stack laws.

law focusUp_focusDown_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.focusUp(I, L, A, S, D, W.focusDown(I, L, A, S, D, s)) == s : W.StackSet<I, L, A, S, D>}

law focusDown_focusUp_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.focusDown(I, L, A, S, D, W.focusUp(I, L, A, S, D, s)) == s : W.StackSet<I, L, A, S, D>}

law swapUp_swapDown_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.swapUp(I, L, A, S, D, W.swapDown(I, L, A, S, D, s)) == s : W.StackSet<I, L, A, S, D>}

law swapDown_swapUp_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.swapDown(I, L, A, S, D, W.swapUp(I, L, A, S, D, s)) == s : W.StackSet<I, L, A, S, D>}

# prop_swap_left_focus, prop_swap_right_focus, prop_swap_master_focus,
# prop_shift_master_focus
law peek_swapUp:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.peek(I, L, A, S, D, W.swapUp(I, L, A, S, D, s)) == W.peek(I, L, A, S, D, s) : Maybe<&2, A>}

law peek_swapDown:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.peek(I, L, A, S, D, W.swapDown(I, L, A, S, D, s)) == W.peek(I, L, A, S, D, s) : Maybe<&2, A>}

law peek_swapMaster:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.peek(I, L, A, S, D, W.swapMaster(I, L, A, S, D, s)) == W.peek(I, L, A, S, D, s) : Maybe<&2, A>}

law peek_shiftMaster:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.peek(I, L, A, S, D, W.shiftMaster(I, L, A, S, D, s)) == W.peek(I, L, A, S, D, s) : Maybe<&2, A>}

# prop_focusMaster_idem, prop_shift_master_idempotent, and swapMaster's
law focusMaster_idem_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.focusMaster(I, L, A, S, D, W.focusMaster(I, L, A, S, D, s)) == W.focusMaster(I, L, A, S, D, s) : W.StackSet<I, L, A, S, D>}

law shiftMaster_idem_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.shiftMaster(I, L, A, S, D, W.shiftMaster(I, L, A, S, D, s)) == W.shiftMaster(I, L, A, S, D, s) : W.StackSet<I, L, A, S, D>}

law swapMaster_idem_set:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.swapMaster(I, L, A, S, D, W.swapMaster(I, L, A, S, D, s)) == W.swapMaster(I, L, A, S, D, s) : W.StackSet<I, L, A, S, D>}

# focusMaster keeps the current workspace's windows in their order
law index_focusMaster:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.index(I, L, A, S, D, W.focusMaster(I, L, A, S, D, s)) == W.index(I, L, A, S, D, s) : List<&2, A>}

# prop_focus_up_local, prop_focus_down_local, prop_focus_master_local,
# prop_swap_master_local, prop_shift_master_local: modify' (which every one
# of them is) changes the current workspace's windows and nothing else.
law modify_visible:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for -f: W.Stack<A> -> W.Stack<A>
  for s: W.StackSet<I, L, A, S, D>
  {W.visible(I, L, A, S, D, W.modify_(I, L, A, S, D, f, s)) == W.visible(I, L, A, S, D, s) : List<&2, W.Screen<I, L, A, S, D>>}

law modify_hidden:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for -f: W.Stack<A> -> W.Stack<A>
  for s: W.StackSet<I, L, A, S, D>
  {W.hidden(I, L, A, S, D, W.modify_(I, L, A, S, D, f, s)) == W.hidden(I, L, A, S, D, s) : List<&2, W.Workspace<I, L, A>>}

law modify_floating:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for -f: W.Stack<A> -> W.Stack<A>
  for s: W.StackSet<I, L, A, S, D>
  {W.floating(I, L, A, S, D, W.modify_(I, L, A, S, D, f, s)) == W.floating(I, L, A, S, D, s) : List<&2, W.Float<A>>}

law modify_currentTag:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for -f: W.Stack<A> -> W.Stack<A>
  for s: W.StackSet<I, L, A, S, D>
  {W.currentTag(I, L, A, S, D, W.modify_(I, L, A, S, D, f, s)) == W.currentTag(I, L, A, S, D, s) : I}

# prop_screens_works
law screens_current_visible:
  for -I: Data
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for s: W.StackSet<I, L, A, S, D>
  {W.screens(I, L, A, S, D, s) == W.current(I, L, A, S, D, s) <> W.visible(I, L, A, S, D, s) : List<&2, W.Screen<I, L, A, S, D>>}

# prop_mapLayoutId, prop_mapWorkspaceId: mapping by the identity changes
# nothing (the identity here ignores the value passed beside it)
def keepL(-K: Data, -L: Data, k: K, l: L) -> L:
  l

def keepW(-K: Data, -I: Data, -L: Data, -A: Data, k: K, w: W.Workspace<I, L, A>) -> W.Workspace<I, L, A>:
  w

law mapLayout_id:
  for ~K: Data
  for ~L: Data
  for -I: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for +k: K
  for s: W.StackSet<I, L, A, S, D>
  {W.mapLayout(~L, ~L, ~K, ~keepL(K, L), I, A, S, D, k, s) == s : W.StackSet<I, L, A, S, D>}

law mapWorkspace_id:
  for ~I: Data
  for ~L: Data
  for ~A: Data
  for ~K: Data
  for -S: Data
  for -D: Data
  for +k: K
  for s: W.StackSet<I, L, A, S, D>
  {W.mapWorkspace(~I, ~L, ~A, ~K, ~keepW(K, I, L, A), S, D, k, s) == s : W.StackSet<I, L, A, S, D>}

# Windows in and out
# ------------------

# insertUp leaves a set that already has the window as it is ...
law insertUp_member:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +a: A
  for +s: W.StackSet<I, L, A, S, D>
  for h: {W.member(~A, ~eqA, I, L, S, D, a, s) == True{} : Bool}
  {W.insertUp(~A, ~eqA, I, L, S, D, a, s) == s : W.StackSet<I, L, A, S, D>}

# ... and puts a new one in focus (prop_insert_peek).
law insertUp_peek:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +a: A
  for +s: W.StackSet<I, L, A, S, D>
  for h: {W.member(~A, ~eqA, I, L, S, D, a, s) == False{} : Bool}
  {W.peek(I, L, A, S, D, W.insertUp(~A, ~eqA, I, L, S, D, a, s)) == Some{a} : Maybe<&2, A>}

# prop_insert_empty, for any set: a window inserted is a member, as long as
# == says a window is itself.
law member_insertUp:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +a: A
  for +s: W.StackSet<I, L, A, S, D>
  for refl: {eqA(a, a) == True{} : Bool}
  {W.member(~A, ~eqA, I, L, S, D, a, W.insertUp(~A, ~eqA, I, L, S, D, a, s)) == True{} : Bool}

# prop_insert_idem
law insertUp_idem:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +a: A
  for +s: W.StackSet<I, L, A, S, D>
  for refl: {eqA(a, a) == True{} : Bool}
  {W.insertUp(~A, ~eqA, I, L, S, D, a, W.insertUp(~A, ~eqA, I, L, S, D, a, s)) == W.insertUp(~A, ~eqA, I, L, S, D, a, s) : W.StackSet<I, L, A, S, D>}

# prop_float_reversible: a window that did not float, floated then sunk,
# leaves the set as it was (compare must say a window is equal to itself).
law float_sink:
  for ~A: Data
  for ~cmpA: A -> A -> Cmp
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +w: A
  for +r: W.RationalRect
  for s: W.StackSet<I, L, A, S, D>
  for +refl: {cmpA(w, w) == EQ{} : Cmp}
  for h: {W.Float.lookup(~A, ~cmpA, w, W.floating(I, L, A, S, D, s)) == None{} : Maybe<&2, W.RationalRect>}
  {W.sink(~A, ~cmpA, I, L, S, D, w, W.float(~A, ~cmpA, I, L, S, D, w, r, s)) == s : W.StackSet<I, L, A, S, D>}

# Viewing
# -------

# prop_view_idem: viewing a workspace twice is viewing it once. (No
# hypothesis: a workspace view brings in is one whose tag == says is i.)
law view_idem:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for +i: I
  for +s: W.StackSet<I, L, A, S, D>
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s)) == W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s) : W.StackSet<I, L, A, S, D>}

# Layouts
# -------
#
# What XMonad.Layout's rectangles keep (tests/Properties/Layout/*.hs).

def Rect.xw(r: L.Rectangle) -> L.Rectangle:
  match r:
    case L.Rectangle{x, y, w, h}:
      L.Rectangle{x, 0, w, 0}

def Rect.yh(r: L.Rectangle) -> L.Rectangle:
  match r:
    case L.Rectangle{x, y, w, h}:
      L.Rectangle{0, y, 0, h}

def Rect.xws(rs: List<&2, L.Rectangle>) -> List<&2, L.Rectangle>:
  match rs:
    case Nil{}:
      Nil{}
    case r <> rest:
      Rect.xw(r) <> Rect.xws(rest)

def Rect.yhs(rs: List<&2, L.Rectangle>) -> List<&2, L.Rectangle>:
  match rs:
    case Nil{}:
      Nil{}
    case r <> rest:
      Rect.yh(r) <> Rect.yhs(rest)

def Rect.rep(n: Nat, +r: L.Rectangle) -> List<&2, L.Rectangle>:
  match n:
    case 0n:
      Nil{}
    case 1n+k:
      r <> Rect.rep(k, r)

def Rects.fst(p: L.Rectangle & L.Rectangle) -> L.Rectangle:
  match p:
    case (a, b):
      a

def Rects.snd(p: L.Rectangle & L.Rectangle) -> L.Rectangle:
  match p:
    case (a, b):
      b

law mirror_twice:
  for r: L.Rectangle
  {L.mirrorRect(L.mirrorRect(r)) == r : L.Rectangle}

# splitVertically n gives max n 1 rectangles ...
law splitVertically_count:
  for n: Nat
  for r: L.Rectangle
  {List.length(&2, L.Rectangle, L.splitVertically(n, r)) == Nat.max(n, 1n) : Nat}

# ... each as wide as r and at r's x (prop_split_horizontal, turned); and
# splitHorizontally's each as high as r and at r's y
law splitVertically_xw:
  for m: Nat
  for -x: U32
  for -y: U32
  for -w: U32
  for -h: U32
  {Rect.xws(L.splitVertically(1n+m, L.Rectangle{x, y, w, h})) == Rect.rep(1n+m, L.Rectangle{x, 0, w, 0}) : List<&2, L.Rectangle>}

law splitHorizontally_yh:
  for +m: Nat
  for +x: U32
  for +y: U32
  for +w: U32
  for +h: U32
  {Rect.yhs(L.splitHorizontally(1n+m, L.Rectangle{x, y, w, h})) == Rect.rep(1n+m, L.Rectangle{0, y, 0, h}) : List<&2, L.Rectangle>}

# prop_split_vertical: splitVerticallyBy keeps x and width in both halves,
# splitHorizontallyBy y and height
law splitVerticallyBy_xw:
  for f: N.Rat
  for +r: L.Rectangle
  {Rect.xw(Rects.fst(L.splitVerticallyBy(f, r))) == Rect.xw(r) : L.Rectangle}

law splitVerticallyBy_xw2:
  for f: N.Rat
  for +r: L.Rectangle
  {Rect.xw(Rects.snd(L.splitVerticallyBy(f, r))) == Rect.xw(r) : L.Rectangle}

law splitHorizontallyBy_yh:
  for f: N.Rat
  for +r: L.Rectangle
  {Rect.yh(Rects.fst(L.splitHorizontallyBy(f, r))) == Rect.yh(r) : L.Rectangle}

law splitHorizontallyBy_yh2:
  for f: N.Rat
  for +r: L.Rectangle
  {Rect.yh(Rects.snd(L.splitHorizontallyBy(f, r))) == Rect.yh(r) : L.Rectangle}

# prop_tile_fullscreen: one window with one master fills the screen
law tile_fullscreen:
  for f: N.Rat
  for +r: L.Rectangle
  {L.tile(f, r, N.Int.of(1n), 1n) == [r] : List<&2, L.Rectangle>}

# no windows, no places
law run_none:
  for -A: Data
  for l: L.Layout
  for +r: L.Rectangle
  {L.Layout.run(A, l, r, None{}) == Nil{} : List<&2, L.Place<A>>}

# prop_purelayout_full: Full shows the focused window, on the whole screen
law run_full:
  for -A: Data
  for +r: L.Rectangle
  for s: W.Stack<A>
  {L.Layout.run(A, L.Full{}, r, Some{s}) == [L.Place{W.Stack.focus(A, s), r}] : List<&2, L.Place<A>>}

# Mirror is the layout on the screen turned, its places turned back
law run_mirror:
  for -A: Data
  for l: L.Layout
  for +r: L.Rectangle
  for m: Maybe<&2, W.Stack<A>>
  {L.Layout.run(A, L.Mirror{l}, r, m) == L.Place.mirror(A, L.Layout.run(A, l, L.mirrorRect(r), m)) : List<&2, L.Place<A>>}

# prop_desc_mirror, prop_desc_full
law desc_mirror:
  for l: L.Layout
  {L.Layout.description(L.Mirror{l}) == "Mirror " ++ L.Layout.description(l) : String}

law desc_full:
  {L.Layout.description(L.Full{}) == "Full" : String}

# prop_sendmsg_full, for every message: Full answers none
law full_ignores:
  for m: L.Msg
  {L.handleMessage(L.Full{}, m) == None{} : Maybe<&2, L.Layout>}

# prop_incmaster_tall: IncMasterN k adds k to the master windows
law incmaster_tall:
  for n: Nat
  for k: Nat
  for d: N.Rat
  for f: N.Rat
  {L.handleMessage(L.Tall{N.Int.of(n), d, f}, L.IncMasterN{N.Int.of(k)}) == Some{L.Tall{N.Int.of(Nat.add(n, k)), d, f}} : Maybe<&2, L.Layout>}

# The default layout: NextLayout goes Tall, Mirror Tall, Full and back to
# Tall; JumpToLayout goes straight to the one named
def Cycle.next(+l: L.Layout) -> L.Layout:
  L.Layout.orig(L.handleMessage(l, L.NextLayout{}), l)

def Cycle.descs(n: Nat, +l: L.Layout) -> List<&2, String>:
  match n:
    case 0n:
      Nil{}
    case 1n+k:
      L.Layout.description(l) <> Cycle.descs(k, Cycle.next(l))

law default_cycle:
  {Cycle.descs(4n, L.Layout.default()) == ["Tall", "Mirror Tall", "Full", "Tall"] : List<&2, String>}

law default_jump_full:
  {L.Layout.description(L.Layout.orig(L.handleMessage(L.Layout.default(), L.JumpToLayout{"Full"}), L.Layout.default())) == "Full" : String}

# prop_purelayout_tall: with a ratio other than 0 and 1, Tall places every
# window of the stack (n master windows, n >= 0) ...
law tall_count:
  for -A: Data
  for +nm: Nat
  for -d: N.Rat
  for +frac: N.Rat
  for +r: L.Rectangle
  for +s: W.Stack<A>
  for h0: {N.Rat.is_eq(frac, L.Rat.zero()) == False{} : Bool}
  for h1: {N.Rat.is_eq(frac, L.Rat.one()) == False{} : Bool}
  {List.length(&2, L.Place<A>, L.Layout.run(A, L.Tall{N.Int.of(nm), d, frac}, r, Some{s})) == List.length(&2, A, W.Stack.integrate(A, s)) : Nat}

# ... for tile gives n windows max n 1 rectangles
law tile_count:
  for +f: N.Rat
  for +r: L.Rectangle
  for nm: Nat
  for +n: Nat
  {List.length(&2, L.Rectangle, L.tile(f, r, N.Int.of(nm), n)) == Nat.max(n, 1n) : Nat}

# With a Choose on the left, NextLayout goes through its layouts first:
# (Tall ||| Full) ||| Mirror Tall goes Tall, Full, Mirror Tall, Tall
law nested_cycle:
  {Cycle.descs(4n, L.Choose{L.CL{}, L.Choose{L.CL{}, L.Layout.tiled(), L.Full{}}, L.Mirror{L.Layout.tiled()}}) == ["Tall", "Full", "Mirror Tall", "Tall"] : List<&2, String>}

# The window manager (Core.bend, Operations.bend)
# -----------------------------------------------

# An event xmonad does not handle changes nothing and asks X for nothing.
law handle_other:
  for c: C.Conf
  for st: C.XState
  {O.handle(c, st, C.EvOther{}) == O.nop(st) : C.Step}

# windows f leaves the windowset at f's answer, the layouts of the
# workspaces it hid told Hide (xmonad's windows: modify, then
# sendMessageWithNoRefresh Hide to each).
law windows_ws:
  for c: C.Conf
  for +old: C.WindowSet()
  for m: List<&2, U32>
  for p: List<&2, C.Pending>
  for n: U32
  for +new: C.WindowSet()
  for mouse: Bool
  {O.st.ws(O.step.st(O.windows(c, C.XState{old, m, p, n}, new, mouse))) == O.ws.hideLayouts(O.scr.tags(C.ws.screens(old)), new) : C.WindowSet()}

# ... and keeps the numlock mask.
law windows_numlock:
  for c: C.Conf
  for old: C.WindowSet()
  for m: List<&2, U32>
  for p: List<&2, C.Pending>
  for +n: U32
  for new: C.WindowSet()
  for mouse: Bool
  {O.st.numlock(O.step.st(O.windows(c, C.XState{old, m, p, n}, new, mouse))) == n : U32}

# On one screen with no floating windows, the windows go where the layout
# puts them, all of the workspace's (windows: flt is empty, tiled the
# whole stack).
law one_screen_tiles:
  for t: String
  for l: L.Layout
  for sid: Nat
  for +r: L.Rectangle
  for +st: Maybe<&2, W.Stack<U32>>
  {O.place.screens(Nil{}, [W.Screen{W.Workspace{t, l, st}, sid, r}], Nil{}) == [L.Layout.run(U32, l, r, st)] : List<&2, List<&2, L.Place<U32>>>}

# XMonad.Config's keys (mod is Alt, mask 8; shift is 1): mod-j focusDown,
# mod-shift-c kill, mod-space NextLayout, mod-shift-q quit, mod-3 shows
# workspace 3, mod-shift-9 sends the window to workspace 9.
law key_focusDown:
  {C.keys.find(8, 106, C.keys()) == Some{C.AFocusDown{}} : Maybe<&2, C.Act>}

law key_kill:
  {C.keys.find(9, 99, C.keys()) == Some{C.AKill{}} : Maybe<&2, C.Act>}

law key_nextLayout:
  {C.keys.find(8, 32, C.keys()) == Some{C.AMsg{L.NextLayout{}}} : Maybe<&2, C.Act>}

law key_quit:
  {C.keys.find(9, 113, C.keys()) == Some{C.AQuit{}} : Maybe<&2, C.Act>}

law key_view3:
  {C.keys.find(8, 51, C.keys()) == Some{C.AGreedyView{"3"}} : Maybe<&2, C.Act>}

law key_shift9:
  {C.keys.find(9, 57, C.keys()) == Some{C.AShift{"9"}} : Maybe<&2, C.Act>}

# NumLock (here mod2, 16) and CapsLock (2) held change no binding.
law cleanMask_locks:
  {C.cleanMask(16, 26) == 8 : U32}

# scan keeps a window that is viewable or iconic and not override-redirect.
law scan_override:
  for w: U32
  for m: U32
  for s: U32
  for rest: List<&2, U32>
  {O.scan.ok(w <> 1 <> m <> s <> rest) == O.scan.ok(rest) : List<&2, U32>}

law scan_viewable:
  for w: U32
  for s: U32
  for rest: List<&2, U32>
  {O.scan.ok(w <> 0 <> 2 <> s <> rest) == w <> O.scan.ok(rest) : List<&2, U32>}

law scan_iconic:
  for w: U32
  for rest: List<&2, U32>
  {O.scan.ok(w <> 0 <> 0 <> 3 <> rest) == w <> O.scan.ok(rest) : List<&2, U32>}

law scan_withdrawn:
  for w: U32
  for rest: List<&2, U32>
  {O.scan.ok(w <> 0 <> 0 <> 0 <> rest) == O.scan.ok(rest) : List<&2, U32>}

# setFocusX: a window with no WM_HINTS gets the input focus; one whose
# WM_HINTS say it takes no input does not; one taking WM_TAKE_FOCUS is
# also sent it, with the event's time.
law focusX_plain:
  for s: U32
  for pr: U32
  for del: U32
  for tf: U32
  for +w: U32
  for t: U32
  {O.focusX(O.Atoms{s, pr, del, tf}, w, t, Nil{}, Nil{}) == [C.SetFocus{w}] : List<&2, C.Cmd>}

law focusX_noinput:
  for s: U32
  for pr: U32
  for del: U32
  for tf: U32
  for +w: U32
  for t: U32
  {O.focusX(O.Atoms{s, pr, del, tf}, w, t, [1, 0], Nil{}) == Nil{} : List<&2, C.Cmd>}

law focusX_takeFocus:
  for s: U32
  for +pr: U32
  for del: U32
  for +tf: U32
  for +w: U32
  for +t: U32
  {O.focusX(O.Atoms{s, pr, del, tf}, w, t, Nil{}, [tf]) == [C.SetFocus{w}, C.SendMessage{w, pr, tf, t}] : List<&2, C.Cmd>}

# killWindow: WM_DELETE_WINDOW to a window that takes it, else XKillClient.
law kill_delete:
  for s: U32
  for +pr: U32
  for +del: U32
  for tf: U32
  for +w: U32
  {O.kill(O.Atoms{s, pr, del, tf}, w, [del]) == [C.SendMessage{w, pr, del, 0}] : List<&2, C.Cmd>}

law kill_client:
  for s: U32
  for pr: U32
  for del: U32
  for tf: U32
  for +w: U32
  {O.kill(O.Atoms{s, pr, del, tf}, w, Nil{}) == [C.KillClient{w}] : List<&2, C.Cmd>}

# isFixedSize: no WM_NORMAL_HINTS is not fixed; min = max is.
law not_fixed_without_hints:
  {O.hints.fixed(C.Hints.none()) == False{} : Bool}

law fixed_min_max:
  for +w: U32
  for +h: U32
  {O.hints.fixed(C.Hints{48, w, h, w, h, 0, 0, 0, 0, 0, 0, 0, 0}) == True{} : Bool}

# applySizeHintsContents with no hints: the size, at least 1 x 1.
law contents_no_hints:
  for +w: U32
  for +h: U32
  {O.hints.contents(C.Hints.none(), w, h) == O.Dim{O.u32.max(1, w), O.u32.max(1, h)} : O.Dim}

# waitingUnmap: a window hidden once waits for one UnmapNotify.
law pending_once:
  for +w: U32
  {O.pending.get(w, O.pending.inc(w, Nil{})) == 1n : Nat}
