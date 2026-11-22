# Laws proposed for the StackSet port, for the human to move into a LAWS.bend
# (or reword or drop): PROOF.bend proves them. They are the properties
# xmonad's own test suite (tests/Properties/*.hs) checks on random values with
# QuickCheck, here proved for every value. A law that needs Haskell's Eq or
# Ord to behave says so as a hypothesis (eqA(a, a) is True, say).

import Base
import ./StackSet.bend as W

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
