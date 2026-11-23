# The proofs of PROPOSED.bend. Nothing here is trusted: `bend PROOF.bend`
# checks every def, `--verdict` rechecks them with BendTT's kernel.

import Base
import ./StackSet.bend as W
import ./Num.bend as N
import ./Layout.bend as L
import ./Core.bend as C
import ./Operations.bend as O
import ./PROPOSED.bend as Proposed

# Lists
# -----

# reverse's loop run twice: what the first one built is undone onto xs
law rev_rev.go:
  for -A: Data
  for xs: List<&2, A>
  for -acc: List<&2, A>
  {List.reverse.go(&2, A, List.reverse.go(&2, A, xs, acc), Nil{}) == List.reverse.go(&2, A, acc, xs) : List<&2, A>}

def rev_rev.go(A, xs, acc):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      rev_rev.go(A, t, h <> acc)

law rev_rev:
  for -A: Data
  for xs: List<&2, A>
  {List.reverse(&2, A, List.reverse(&2, A, xs)) == xs : List<&2, A>}

def rev_rev(A, xs):
  rev_rev.go(A, xs, Nil{})

# Stack.top's stand-in for an empty list is never used when reverse's loop
# starts from a nonempty list
law top_any:
  for -A: Data
  for ys: List<&2, A>
  for -x: A
  for -acc: List<&2, A>
  for -a: A
  for -b: A
  {W.Stack.top(A, List.reverse.go(&2, A, ys, x <> acc), a) == W.Stack.top(A, List.reverse.go(&2, A, ys, x <> acc), b) : W.Stack<A>}

def top_any(A, ys, x, acc, a, b):
  match ys:
    case Nil{}:
      {==}
    case h <> t:
      top_any(A, t, h, x <> acc, a, b)

# focusUp after a wrap: the stack topped by zs, read the other way round and
# focused up, is the stack topped by zs reversed
law up_rev_top:
  for -A: Data
  for zs: List<&2, A>
  for -t: A
  {W.Stack.focusUp(A, W.Stack.reverse(A, W.Stack.top(A, zs, t))) == W.Stack.top(A, List.reverse(&2, A, zs), t) : W.Stack<A>}

def up_rev_top(A, zs, t):
  match zs:
    case Nil{}:
      {==}
    case x <> rest:
      top_any(A, rest, x, Nil{}, x, t)

# Stacks
# ------

def Proposed.stack_reverse_twice(A, s):
  match s:
    case W.Stack{t, l, r}:
      {==}

def Proposed.integrate_differentiate(A, xs):
  match xs:
    case Nil{}:
      {==}
    case x <> rest:
      {==}

def Proposed.focusUp_focusDown(A, s):
  match s:
    case W.Stack{+t, +ls, rs}:
      match rs:
        case r <> rr:
          {==}
        case Nil{}:
          %Equal.sym(W.Stack<A>, W.Stack.focusUp(A, W.Stack.reverse(A, W.Stack.top(A, List.reverse(&2, A, t <> ls), t))), W.Stack.top(A, List.reverse(&2, A, List.reverse(&2, A, t <> ls)), t), up_rev_top(A, List.reverse(&2, A, t <> ls), t)) : {_ == W.Stack{t, ls, Nil{}} : W.Stack<A>}
          %Equal.sym(List<&2, A>, List.reverse(&2, A, List.reverse(&2, A, t <> ls)), t <> ls, rev_rev(A, t <> ls)) : {W.Stack.top(A, _, t) == W.Stack{t, ls, Nil{}} : W.Stack<A>}
          {==}

def Proposed.focusDown_focusUp(A, s):
  match s:
    case W.Stack{+t, ls, +rs}:
      match ls:
        case l <> ll:
          {==}
        case Nil{}:
          %Equal.sym(W.Stack<A>, W.Stack.focusUp(A, W.Stack.reverse(A, W.Stack.top(A, List.reverse(&2, A, t <> rs), t))), W.Stack.top(A, List.reverse(&2, A, List.reverse(&2, A, t <> rs)), t), up_rev_top(A, List.reverse(&2, A, t <> rs), t)) : {W.Stack.reverse(A, _) == W.Stack{t, Nil{}, rs} : W.Stack<A>}
          %Equal.sym(List<&2, A>, List.reverse(&2, A, List.reverse(&2, A, t <> rs)), t <> rs, rev_rev(A, t <> rs)) : {W.Stack.reverse(A, W.Stack.top(A, _, t)) == W.Stack{t, Nil{}, rs} : W.Stack<A>}
          {==}

def Proposed.swapUp_swapDown(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match rs:
        case r <> rr:
          {==}
        case Nil{}:
          %Equal.sym(List<&2, A>, List.reverse(&2, A, List.reverse(&2, A, ls)), ls, rev_rev(A, ls)) : {W.Stack{t, _, Nil{}} == W.Stack{t, ls, Nil{}} : W.Stack<A>}
          {==}

def Proposed.swapDown_swapUp(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case l <> ll:
          {==}
        case Nil{}:
          %Equal.sym(List<&2, A>, List.reverse(&2, A, List.reverse(&2, A, rs)), rs, rev_rev(A, rs)) : {W.Stack{t, Nil{}, _} == W.Stack{t, Nil{}, rs} : W.Stack<A>}
          {==}

def Proposed.swapUp_focus(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case l <> ll:
          {==}
        case Nil{}:
          {==}

def Proposed.swapDown_focus(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match rs:
        case r <> rr:
          {==}
        case Nil{}:
          {==}

law sm_go_focus:
  for -A: Data
  for xs: List<&2, A>
  for -t: A
  for -rs: List<&2, A>
  {W.Stack.focus(A, W.Stack.swapMaster.go(A, xs, t, rs)) == t : A}

def sm_go_focus(A, xs, t, rs):
  match xs:
    case x <> rest:
      {==}
    case Nil{}:
      {==}

def Proposed.swapMaster_focus(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case Nil{}:
          {==}
        case l <> ll:
          sm_go_focus(A, List.reverse(&2, A, l <> ll), t, rs)

def Proposed.shiftMaster_focus(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case Nil{}:
          {==}
        case l <> ll:
          {==}

law fm_go_integrate:
  for -A: Data
  for xs: List<&2, A>
  for -t: A
  for -rs: List<&2, A>
  {W.Stack.integrate(A, W.Stack.focusMaster.go(A, xs, t, rs)) == List.append(&2, A, xs, t <> rs) : List<&2, A>}

def fm_go_integrate(A, xs, t, rs):
  match xs:
    case x <> rest:
      {==}
    case Nil{}:
      {==}

def Proposed.focusMaster_integrate(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case Nil{}:
          {==}
        case l <> ll:
          fm_go_integrate(A, List.reverse(&2, A, l <> ll), t, rs)

law fm_go_idem:
  for -A: Data
  for xs: List<&2, A>
  for -t: A
  for -rs: List<&2, A>
  {W.Stack.focusMaster(A, W.Stack.focusMaster.go(A, xs, t, rs)) == W.Stack.focusMaster.go(A, xs, t, rs) : W.Stack<A>}

def fm_go_idem(A, xs, t, rs):
  match xs:
    case x <> rest:
      {==}
    case Nil{}:
      {==}

def Proposed.focusMaster_idem(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case Nil{}:
          {==}
        case l <> ll:
          fm_go_idem(A, List.reverse(&2, A, l <> ll), t, rs)

def Proposed.shiftMaster_idem(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case Nil{}:
          {==}
        case l <> ll:
          {==}

law sm_go_idem:
  for -A: Data
  for xs: List<&2, A>
  for -t: A
  for -rs: List<&2, A>
  {W.Stack.swapMaster(A, W.Stack.swapMaster.go(A, xs, t, rs)) == W.Stack.swapMaster.go(A, xs, t, rs) : W.Stack<A>}

def sm_go_idem(A, xs, t, rs):
  match xs:
    case x <> rest:
      {==}
    case Nil{}:
      {==}

def Proposed.swapMaster_idem(A, s):
  match s:
    case W.Stack{t, ls, rs}:
      match ls:
        case Nil{}:
          {==}
        case l <> ll:
          sm_go_idem(A, List.reverse(&2, A, l <> ll), t, rs)

# Stack as a Functor
# ------------------

law map_list_id:
  for ~A: Data
  for xs: List<&2, A>
  {W.Stack.map.list(~A, ~A, ~Proposed.ident(A), xs) == xs : List<&2, A>}

def map_list_id(A, xs):
  match xs:
    case Nil{}:
      {==}
    case x <> rest:
      %map_list_id(A, rest) : {W.Stack.map.list(~A, ~A, ~Proposed.ident(A), x <> rest) == x <> _ : List<&2, A>}
      {==}

def Proposed.stack_map_id(A, s):
  match s:
    case W.Stack{t, l, r}:
      %map_list_id(A, l) : {W.Stack.map(~A, ~A, ~Proposed.ident(A), W.Stack{t, l, r}) == W.Stack{t, _, r} : W.Stack<A>}
      %map_list_id(A, r) : {W.Stack.map(~A, ~A, ~Proposed.ident(A), W.Stack{t, l, r}) == W.Stack{t, W.Stack.map.list(~A, ~A, ~Proposed.ident(A), l), _} : W.Stack<A>}
      {==}

law map_list_comp:
  for ~A: Data
  for ~B: Data
  for ~C: Data
  for ~f: A -> B
  for ~g: B -> C
  for xs: List<&2, A>
  {W.Stack.map.list(~B, ~C, ~g, W.Stack.map.list(~A, ~B, ~f, xs)) == W.Stack.map.list(~A, ~C, ~Proposed.comp(~A, ~B, ~C, ~f, ~g), xs) : List<&2, C>}

def map_list_comp(A, B, C, f, g, xs):
  match xs:
    case Nil{}:
      {==}
    case x <> rest:
      %map_list_comp(A, B, C, f, g, rest) : {W.Stack.map.list(~B, ~C, ~g, W.Stack.map.list(~A, ~B, ~f, x <> rest)) == g(f(x)) <> _ : List<&2, C>}
      {==}

def Proposed.stack_map_comp(A, B, C, f, g, s):
  match s:
    case W.Stack{t, l, r}:
      %map_list_comp(A, B, C, f, g, l) : {W.Stack.map(~B, ~C, ~g, W.Stack.map(~A, ~B, ~f, W.Stack{t, l, r})) == W.Stack{g(f(t)), _, W.Stack.map.list(~A, ~C, ~Proposed.comp(~A, ~B, ~C, ~f, ~g), r)} : W.Stack<C>}
      %map_list_comp(A, B, C, f, g, r) : {W.Stack.map(~B, ~C, ~g, W.Stack.map(~A, ~B, ~f, W.Stack{t, l, r})) == W.Stack{g(f(t)), W.Stack.map.list(~B, ~C, ~g, W.Stack.map.list(~A, ~B, ~f, l)), _} : W.Stack<C>}
      {==}

# The set
# -------
#
# Each lifted law: the set taken apart down to the current stack; with no
# stack nothing moves, with one the stack law rewrites it.

def Proposed.focusUp_focusDown_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.focusUp_focusDown(A, x) : {W.focusUp(I, L, A, S, D, W.focusDown(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.focusDown_focusUp_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.focusDown_focusUp(A, x) : {W.focusDown(I, L, A, S, D, W.focusUp(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.swapUp_swapDown_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.swapUp_swapDown(A, x) : {W.swapUp(I, L, A, S, D, W.swapDown(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.swapDown_swapUp_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.swapDown_swapUp(A, x) : {W.swapDown(I, L, A, S, D, W.swapUp(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.peek_swapUp(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.swapUp_focus(A, x) : {W.peek(I, L, A, S, D, W.swapUp(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == Some{_} : Maybe<&2, A>}
          {==}

def Proposed.peek_swapDown(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.swapDown_focus(A, x) : {W.peek(I, L, A, S, D, W.swapDown(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == Some{_} : Maybe<&2, A>}
          {==}

def Proposed.peek_swapMaster(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.swapMaster_focus(A, x) : {W.peek(I, L, A, S, D, W.swapMaster(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == Some{_} : Maybe<&2, A>}
          {==}

def Proposed.peek_shiftMaster(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.shiftMaster_focus(A, x) : {W.peek(I, L, A, S, D, W.shiftMaster(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == Some{_} : Maybe<&2, A>}
          {==}

def Proposed.focusMaster_idem_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.focusMaster_idem(A, x) : {W.focusMaster(I, L, A, S, D, W.focusMaster(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.shiftMaster_idem_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.shiftMaster_idem(A, x) : {W.shiftMaster(I, L, A, S, D, W.shiftMaster(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.swapMaster_idem_set(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.swapMaster_idem(A, x) : {W.swapMaster(I, L, A, S, D, W.swapMaster(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == W.StackSet{W.Screen{W.Workspace{t, l, Some{_}}, sc, sd}, v, h, fl} : W.StackSet<I, L, A, S, D>}
          {==}

def Proposed.index_focusMaster(I, L, A, S, D, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{x}:
          %Proposed.focusMaster_integrate(A, x) : {W.index(I, L, A, S, D, W.focusMaster(I, L, A, S, D, W.StackSet{W.Screen{W.Workspace{t, l, Some{x}}, sc, sd}, v, h, fl})) == _ : List<&2, A>}
          {==}

def Proposed.modify_visible(I, L, A, S, D, f, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      {==}

def Proposed.modify_hidden(I, L, A, S, D, f, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      {==}

def Proposed.modify_floating(I, L, A, S, D, f, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      {==}

def Proposed.modify_currentTag(I, L, A, S, D, f, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      {==}

def Proposed.screens_current_visible(I, L, A, S, D, s):
  match s:
    case W.StackSet{c, v, h, fl}:
      {==}

law relayoutAll_id:
  for ~K: Data
  for ~L: Data
  for -I: Data
  for -A: Data
  for +k: K
  for xs: List<&2, W.Workspace<I, L, A>>
  {W.Workspace.relayoutAll(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, k, xs) == xs : List<&2, W.Workspace<I, L, A>>}

def relayoutAll_id(K, L, I, A, k, xs):
  match xs:
    case Nil{}:
      {==}
    case W.Workspace{t, l, st} <> rest:
      %relayoutAll_id(K, L, I, A, k, rest) : {W.Workspace.relayoutAll(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, k, W.Workspace{t, l, st} <> rest) == W.Workspace{t, l, st} <> _ : List<&2, W.Workspace<I, L, A>>}
      {==}

law screen_relayoutAll_id:
  for ~K: Data
  for ~L: Data
  for -I: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for +k: K
  for xs: List<&2, W.Screen<I, L, A, S, D>>
  {W.Screen.relayoutAll(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, S, D, k, xs) == xs : List<&2, W.Screen<I, L, A, S, D>>}

def screen_relayoutAll_id(K, L, I, A, S, D, k, xs):
  match xs:
    case Nil{}:
      {==}
    case W.Screen{W.Workspace{t, l, st}, sc, sd} <> rest:
      %screen_relayoutAll_id(K, L, I, A, S, D, k, rest) : {W.Screen.relayoutAll(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, S, D, k, W.Screen{W.Workspace{t, l, st}, sc, sd} <> rest) == W.Screen{W.Workspace{t, l, st}, sc, sd} <> _ : List<&2, W.Screen<I, L, A, S, D>>}
      {==}

def Proposed.mapLayout_id(K, L, I, A, S, D, k, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      %screen_relayoutAll_id(K, L, I, A, S, D, k, v) : {W.mapLayout(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, S, D, k, W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}) == W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, _, h, fl} : W.StackSet<I, L, A, S, D>}
      %relayoutAll_id(K, L, I, A, k, h) : {W.mapLayout(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, S, D, k, W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}) == W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, W.Screen.relayoutAll(~L, ~L, ~K, ~Proposed.keepL(K, L), I, A, S, D, k, v), _, fl} : W.StackSet<I, L, A, S, D>}
      {==}

law mapAll_id:
  for ~I: Data
  for ~L: Data
  for ~A: Data
  for ~K: Data
  for +k: K
  for xs: List<&2, W.Workspace<I, L, A>>
  {W.Workspace.mapAll(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), k, xs) == xs : List<&2, W.Workspace<I, L, A>>}

def mapAll_id(I, L, A, K, k, xs):
  match xs:
    case Nil{}:
      {==}
    case x <> rest:
      %mapAll_id(I, L, A, K, k, rest) : {W.Workspace.mapAll(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), k, x <> rest) == x <> _ : List<&2, W.Workspace<I, L, A>>}
      {==}

law screen_mapAll_id:
  for ~I: Data
  for ~L: Data
  for ~A: Data
  for ~K: Data
  for -S: Data
  for -D: Data
  for +k: K
  for xs: List<&2, W.Screen<I, L, A, S, D>>
  {W.Screen.mapAll(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), S, D, k, xs) == xs : List<&2, W.Screen<I, L, A, S, D>>}

def screen_mapAll_id(I, L, A, K, S, D, k, xs):
  match xs:
    case Nil{}:
      {==}
    case W.Screen{w, sc, sd} <> rest:
      %screen_mapAll_id(I, L, A, K, S, D, k, rest) : {W.Screen.mapAll(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), S, D, k, W.Screen{w, sc, sd} <> rest) == W.Screen{w, sc, sd} <> _ : List<&2, W.Screen<I, L, A, S, D>>}
      {==}

def Proposed.mapWorkspace_id(I, L, A, K, S, D, k, s):
  match s:
    case W.StackSet{W.Screen{w, sc, sd}, v, h, fl}:
      %screen_mapAll_id(I, L, A, K, S, D, k, v) : {W.mapWorkspace(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), S, D, k, W.StackSet{W.Screen{w, sc, sd}, v, h, fl}) == W.StackSet{W.Screen{w, sc, sd}, _, h, fl} : W.StackSet<I, L, A, S, D>}
      %mapAll_id(I, L, A, K, k, h) : {W.mapWorkspace(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), S, D, k, W.StackSet{W.Screen{w, sc, sd}, v, h, fl}) == W.StackSet{W.Screen{w, sc, sd}, W.Screen.mapAll(~I, ~L, ~A, ~K, ~Proposed.keepW(K, I, L, A), S, D, k, v), _, fl} : W.StackSet<I, L, A, S, D>}
      {==}

# Windows in and out
# ------------------

law ex_falso:
  for -G: Type
  for e: Empty
  G

def ex_falso(G, e):
  match e:

def Proposed.insertUp_member(A, eqA, I, L, S, D, a, s, h):
  %Equal.sym(Bool, W.member(~A, ~eqA, I, L, S, D, a, s), True{}, h) : {W.Bool.if(W.StackSet<I, L, A, S, D>, _, q => s, q => W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s)) == s : W.StackSet<I, L, A, S, D>}
  {==}

# insertUp of a new window is modify's
law insertUp_new:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for -a: A
  for -s: W.StackSet<I, L, A, S, D>
  for h: {W.member(~A, ~eqA, I, L, S, D, a, s) == False{} : Bool}
  {W.insertUp(~A, ~eqA, I, L, S, D, a, s) == W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s) : W.StackSet<I, L, A, S, D>}

def insertUp_new(A, eqA, I, L, S, D, a, s, h):
  %Equal.sym(Bool, W.member(~A, ~eqA, I, L, S, D, a, s), False{}, h) : {W.Bool.if(W.StackSet<I, L, A, S, D>, _, q => s, q => W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s)) == W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s) : W.StackSet<I, L, A, S, D>}
  {==}

# the window modify puts in is in focus
law peek_ins:
  for -A: Data
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for -a: A
  for s: W.StackSet<I, L, A, S, D>
  {W.peek(I, L, A, S, D, W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s)) == Some{a} : Maybe<&2, A>}

def peek_ins(A, I, L, S, D, a, s):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          {==}
        case Some{y}:
          match y:
            case W.Stack{f, u, d}:
              {==}

def Proposed.insertUp_peek(A, eqA, I, L, S, D, a, s, h):
  %Equal.sym(W.StackSet<I, L, A, S, D>, W.insertUp(~A, ~eqA, I, L, S, D, a, s), W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s), insertUp_new(A, eqA, I, L, S, D, a, s, h)) : {W.peek(I, L, A, S, D, _) == Some{a} : Maybe<&2, A>}
  peek_ins(A, I, L, S, D, a, s)

# and is a member: the current workspace comes first, and holds it
law member_ins:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for -a: A
  for s: W.StackSet<I, L, A, S, D>
  for refl: {eqA(a, a) == True{} : Bool}
  {W.member(~A, ~eqA, I, L, S, D, a, W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s)) == True{} : Bool}

def member_ins(A, eqA, I, L, S, D, a, s, refl):
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, fl}:
      match st:
        case None{}:
          %Equal.sym(Bool, eqA(a, a), True{}, refl) : {Maybe.is_some(&2, I, W.Bool.if(Maybe<&2, I>, Bool.or(_, False{}), q => Some{t}, q => W.Workspace.findWin(~A, ~eqA, I, L, a, W.Screen.workspaces(I, L, A, S, D, v, h)))) == True{} : Bool}
          {==}
        case Some{y}:
          match y:
            case W.Stack{f, u, d}:
              %Equal.sym(Bool, eqA(a, a), True{}, refl) : {Maybe.is_some(&2, I, W.Bool.if(Maybe<&2, I>, Bool.or(_, W.List.elem(~A, ~eqA, a, List.append(&2, A, u, f <> d))), q => Some{t}, q => W.Workspace.findWin(~A, ~eqA, I, L, a, W.Screen.workspaces(I, L, A, S, D, v, h)))) == True{} : Bool}
              {==}

law member_insertUp.go:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +a: A
  for +s: W.StackSet<I, L, A, S, D>
  for refl: {eqA(a, a) == True{} : Bool}
  for b: Bool
  for +e: {W.member(~A, ~eqA, I, L, S, D, a, s) == b : Bool}
  {W.member(~A, ~eqA, I, L, S, D, a, W.insertUp(~A, ~eqA, I, L, S, D, a, s)) == True{} : Bool}

def member_insertUp.go(A, eqA, I, L, S, D, a, s, refl, b, e):
  match b:
    case True{}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.insertUp(~A, ~eqA, I, L, S, D, a, s), s, Proposed.insertUp_member(A, eqA, I, L, S, D, a, s, e)) : {W.member(~A, ~eqA, I, L, S, D, a, _) == True{} : Bool}
      e
    case False{}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.insertUp(~A, ~eqA, I, L, S, D, a, s), W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s), insertUp_new(A, eqA, I, L, S, D, a, s, e)) : {W.member(~A, ~eqA, I, L, S, D, a, _) == True{} : Bool}
      member_ins(A, eqA, I, L, S, D, a, s, refl)

def Proposed.member_insertUp(A, eqA, I, L, S, D, a, s, refl):
  member_insertUp.go(A, eqA, I, L, S, D, a, s, refl, W.member(~A, ~eqA, I, L, S, D, a, s), {==})

law insertUp_idem.go:
  for ~A: Data
  for ~eqA: A -> A -> Bool
  for -I: Data
  for -L: Data
  for -S: Data
  for -D: Data
  for +a: A
  for +s: W.StackSet<I, L, A, S, D>
  for refl: {eqA(a, a) == True{} : Bool}
  for b: Bool
  for +e: {W.member(~A, ~eqA, I, L, S, D, a, s) == b : Bool}
  {W.insertUp(~A, ~eqA, I, L, S, D, a, W.insertUp(~A, ~eqA, I, L, S, D, a, s)) == W.insertUp(~A, ~eqA, I, L, S, D, a, s) : W.StackSet<I, L, A, S, D>}

def insertUp_idem.go(A, eqA, I, L, S, D, a, s, refl, b, e):
  match b:
    case True{}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.insertUp(~A, ~eqA, I, L, S, D, a, s), s, Proposed.insertUp_member(A, eqA, I, L, S, D, a, s, e)) : {W.insertUp(~A, ~eqA, I, L, S, D, a, _) == _ : W.StackSet<I, L, A, S, D>}
      Proposed.insertUp_member(A, eqA, I, L, S, D, a, s, e)
    case False{}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.insertUp(~A, ~eqA, I, L, S, D, a, s), W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s), insertUp_new(A, eqA, I, L, S, D, a, s, e)) : {W.insertUp(~A, ~eqA, I, L, S, D, a, _) == _ : W.StackSet<I, L, A, S, D>}
      Proposed.insertUp_member(A, eqA, I, L, S, D, a, W.modify(I, L, A, S, D, Some{W.Stack{a, Nil{}, Nil{}}}, x => W.insertUp.ins(A, a, x), s), member_ins(A, eqA, I, L, S, D, a, s, refl))

def Proposed.insertUp_idem(A, eqA, I, L, S, D, a, s, refl):
  insertUp_idem.go(A, eqA, I, L, S, D, a, s, refl, W.member(~A, ~eqA, I, L, S, D, a, s), {==})

# Floating
# --------

def msome(m: Maybe<&2, W.RationalRect>) -> Type:
  match m:
    case None{}:
      Empty
    case Some{x}:
      Unit

# a window compare finds equal to a floating one floats
law lookup_eq_clash:
  for ~A: Data
  for ~cmpA: A -> A -> Cmp
  for -w: A
  for -k: A
  for -v: W.RationalRect
  for -rest: List<&2, W.Float<A>>
  for h: {W.Float.lookup(~A, ~cmpA, w, W.Float{k, v} <> rest) == None{} : Maybe<&2, W.RationalRect>}
  for e: {cmpA(w, k) == EQ{} : Cmp}
  Empty

def lookup_eq_clash(A, cmpA, w, k, v, rest, h, e):
  %h : msome(_)
  %Equal.sym(Cmp, cmpA(w, k), EQ{}, e) : msome(W.Cmp.case(Maybe<&2, W.RationalRect>, _, q => None{}, q => Some{v}, q => W.Float.lookup(~A, ~cmpA, w, rest)))
  Unit{}

# past a smaller key, the lookup goes on in the rest
law lookup_gt:
  for ~A: Data
  for ~cmpA: A -> A -> Cmp
  for -w: A
  for -k: A
  for -v: W.RationalRect
  for -rest: List<&2, W.Float<A>>
  for h: {W.Float.lookup(~A, ~cmpA, w, W.Float{k, v} <> rest) == None{} : Maybe<&2, W.RationalRect>}
  for e: {cmpA(w, k) == GT{} : Cmp}
  {W.Float.lookup(~A, ~cmpA, w, rest) == None{} : Maybe<&2, W.RationalRect>}

def lookup_gt(A, cmpA, w, k, v, rest, h, e):
  Equal.trans(Maybe<&2, W.RationalRect>, W.Float.lookup(~A, ~cmpA, w, rest), W.Float.lookup(~A, ~cmpA, w, W.Float{k, v} <> rest), None{},
    Equal.sym(Maybe<&2, W.RationalRect>, W.Float.lookup(~A, ~cmpA, w, W.Float{k, v} <> rest), W.Float.lookup(~A, ~cmpA, w, rest),
      Equal.cong(Cmp, Maybe<&2, W.RationalRect>, x => W.Cmp.case(Maybe<&2, W.RationalRect>, x, q => None{}, q => Some{v}, q => W.Float.lookup(~A, ~cmpA, w, rest)), cmpA(w, k), GT{}, e)),
    h)

law del_ins.c:
  for ~A: Data
  for ~cmpA: A -> A -> Cmp
  for +w: A
  for +r: W.RationalRect
  for +k: A
  for +v: W.RationalRect
  for +rest: List<&2, W.Float<A>>
  for +refl: {cmpA(w, w) == EQ{} : Cmp}
  for ih: {W.Float.lookup(~A, ~cmpA, w, rest) == None{} : Maybe<&2, W.RationalRect>} -> {W.Float.delete(~A, ~cmpA, w, W.Float.insert(~A, ~cmpA, w, r, rest)) == rest : List<&2, W.Float<A>>}
  for h: {W.Float.lookup(~A, ~cmpA, w, W.Float{k, v} <> rest) == None{} : Maybe<&2, W.RationalRect>}
  for c: Cmp
  for +e: {cmpA(w, k) == c : Cmp}
  {W.Float.delete(~A, ~cmpA, w, W.Float.insert(~A, ~cmpA, w, r, W.Float{k, v} <> rest)) == W.Float{k, v} <> rest : List<&2, W.Float<A>>}

def del_ins.c(A, cmpA, w, r, k, v, rest, refl, ih, h, c, e):
  match c:
    case LT{}:
      %Equal.sym(Cmp, cmpA(w, k), LT{}, e) : {W.Float.delete(~A, ~cmpA, w, W.Cmp.case(List<&2, W.Float<A>>, _, q => W.Float{w, r} <> W.Float{k, v} <> rest, q => W.Float{w, r} <> rest, q => W.Float{k, v} <> W.Float.insert(~A, ~cmpA, w, r, rest))) == W.Float{k, v} <> rest : List<&2, W.Float<A>>}
      %Equal.sym(Cmp, cmpA(w, w), EQ{}, refl) : {W.Cmp.case(List<&2, W.Float<A>>, _, q => W.Float{w, r} <> W.Float{k, v} <> rest, q => W.Float{k, v} <> rest, q => W.Float{w, r} <> W.Float.delete(~A, ~cmpA, w, W.Float{k, v} <> rest)) == W.Float{k, v} <> rest : List<&2, W.Float<A>>}
      {==}
    case EQ{}:
      ex_falso({W.Float.delete(~A, ~cmpA, w, W.Float.insert(~A, ~cmpA, w, r, W.Float{k, v} <> rest)) == W.Float{k, v} <> rest : List<&2, W.Float<A>>}, lookup_eq_clash(A, cmpA, w, k, v, rest, h, e))
    case GT{}:
      %Equal.sym(Cmp, cmpA(w, k), GT{}, e) : {W.Float.delete(~A, ~cmpA, w, W.Cmp.case(List<&2, W.Float<A>>, _, q => W.Float{w, r} <> W.Float{k, v} <> rest, q => W.Float{w, r} <> rest, q => W.Float{k, v} <> W.Float.insert(~A, ~cmpA, w, r, rest))) == W.Float{k, v} <> rest : List<&2, W.Float<A>>}
      %Equal.sym(Cmp, cmpA(w, k), GT{}, e) : {W.Cmp.case(List<&2, W.Float<A>>, _, q => W.Float{k, v} <> W.Float.insert(~A, ~cmpA, w, r, rest), q => W.Float.insert(~A, ~cmpA, w, r, rest), q => W.Float{k, v} <> W.Float.delete(~A, ~cmpA, w, W.Float.insert(~A, ~cmpA, w, r, rest))) == W.Float{k, v} <> rest : List<&2, W.Float<A>>}
      %ih(lookup_gt(A, cmpA, w, k, v, rest, h, e)) : {W.Float{k, v} <> W.Float.delete(~A, ~cmpA, w, W.Float.insert(~A, ~cmpA, w, r, rest)) == W.Float{k, v} <> _ : List<&2, W.Float<A>>}
      {==}

law del_ins:
  for ~A: Data
  for ~cmpA: A -> A -> Cmp
  for +w: A
  for +r: W.RationalRect
  for xs: List<&2, W.Float<A>>
  for +refl: {cmpA(w, w) == EQ{} : Cmp}
  for h: {W.Float.lookup(~A, ~cmpA, w, xs) == None{} : Maybe<&2, W.RationalRect>}
  {W.Float.delete(~A, ~cmpA, w, W.Float.insert(~A, ~cmpA, w, r, xs)) == xs : List<&2, W.Float<A>>}

def del_ins(A, cmpA, w, r, xs, refl, h):
  match xs:
    case Nil{}:
      %Equal.sym(Cmp, cmpA(w, w), EQ{}, refl) : {W.Cmp.case(List<&2, W.Float<A>>, _, q => W.Float{w, r} <> Nil{}, q => Nil{}, q => W.Float{w, r} <> Nil{}) == Nil{} : List<&2, W.Float<A>>}
      {==}
    case W.Float{+k, +v} <> +rest:
      del_ins.c(A, cmpA, w, r, k, v, rest, refl, h2 => del_ins(A, cmpA, w, r, rest, refl, h2), h, cmpA(w, k), {==})

def Proposed.float_sink(A, cmpA, I, L, S, D, w, r, s, refl, h):
  match s:
    case W.StackSet{c, v, hh, f}:
      %del_ins(A, cmpA, w, r, f, refl, h) : {W.sink(~A, ~cmpA, I, L, S, D, w, W.float(~A, ~cmpA, I, L, S, D, w, r, W.StackSet{c, v, hh, f})) == W.StackSet{c, v, hh, _} : W.StackSet<I, L, A, S, D>}
      {==}

# Viewing
# -------

def none.ty(-A: Data, m: Maybe<&2, A>) -> Type:
  match m:
    case None{}:
      Unit
    case Some{z}:
      Empty

law none_clash:
  for -A: Data
  for -x: A
  for h: {None{} == Some{x} : Maybe<&2, A>}
  Empty

def none_clash(A, x, h):
  %h : none.ty(A, _)
  Unit{}

def unSome(-A: Data, m: Maybe<&2, A>, d: A) -> A:
  match m:
    case None{}:
      d
    case Some{z}:
      z

# what findTag finds has tag i (by ==)
law findTag_hit.c:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for -i: I
  for -y: W.Screen<I, L, A, S, D>
  for -rest: List<&2, W.Screen<I, L, A, S, D>>
  for -x: W.Screen<I, L, A, S, D>
  for ih: {W.Screen.findTag(~I, ~eqI, L, A, S, D, i, rest) == Some{x} : Maybe<&2, W.Screen<I, L, A, S, D>>} -> {eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, x))) == True{} : Bool}
  for b: Bool
  for eb: {eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, y))) == b : Bool}
  for h: {List.find.if(W.Screen<I, L, A, S, D>, y, q => W.Screen.findTag(~I, ~eqI, L, A, S, D, i, rest), b) == Some{x} : Maybe<&2, W.Screen<I, L, A, S, D>>}
  {eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, x))) == True{} : Bool}

def findTag_hit.c(I, eqI, L, A, S, D, i, y, rest, x, ih, b, eb, h):
  match b:
    case True{}:
      %Equal.cong(Maybe<&2, W.Screen<I, L, A, S, D>>, W.Screen<I, L, A, S, D>, m => unSome(W.Screen<I, L, A, S, D>, m, y), Some{y}, Some{x}, h) : {eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, _))) == True{} : Bool}
      eb
    case False{}:
      ih(h)

law findTag_hit:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for -L: Data
  for -A: Data
  for -S: Data
  for -D: Data
  for +i: I
  for xs: List<&2, W.Screen<I, L, A, S, D>>
  for -x: W.Screen<I, L, A, S, D>
  for h: {W.Screen.findTag(~I, ~eqI, L, A, S, D, i, xs) == Some{x} : Maybe<&2, W.Screen<I, L, A, S, D>>}
  {eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, x))) == True{} : Bool}

def findTag_hit(I, eqI, L, A, S, D, i, xs, x, h):
  match xs:
    case Nil{}:
      ex_falso({eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, x))) == True{} : Bool}, none_clash(W.Screen<I, L, A, S, D>, x, h))
    case +y <> rest:
      findTag_hit.c(I, eqI, L, A, S, D, i, y, rest, x, h2 => findTag_hit(I, eqI, L, A, S, D, i, rest, x, h2), eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, y))), {==}, h)

# what find finds among the workspaces has tag i (by ==)
law find_hit.c:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for -L: Data
  for -A: Data
  for -i: I
  for -y: W.Workspace<I, L, A>
  for -rest: List<&2, W.Workspace<I, L, A>>
  for -x: W.Workspace<I, L, A>
  for ih: {W.Workspace.find(~I, ~eqI, L, A, i, rest) == Some{x} : Maybe<&2, W.Workspace<I, L, A>>} -> {eqI(i, W.Workspace.tag(I, L, A, x)) == True{} : Bool}
  for b: Bool
  for eb: {eqI(i, W.Workspace.tag(I, L, A, y)) == b : Bool}
  for h: {List.find.if(W.Workspace<I, L, A>, y, q => W.Workspace.find(~I, ~eqI, L, A, i, rest), b) == Some{x} : Maybe<&2, W.Workspace<I, L, A>>}
  {eqI(i, W.Workspace.tag(I, L, A, x)) == True{} : Bool}

def find_hit.c(I, eqI, L, A, i, y, rest, x, ih, b, eb, h):
  match b:
    case True{}:
      %Equal.cong(Maybe<&2, W.Workspace<I, L, A>>, W.Workspace<I, L, A>, m => unSome(W.Workspace<I, L, A>, m, y), Some{y}, Some{x}, h) : {eqI(i, W.Workspace.tag(I, L, A, _)) == True{} : Bool}
      eb
    case False{}:
      ih(h)

law find_hit:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for -L: Data
  for -A: Data
  for +i: I
  for xs: List<&2, W.Workspace<I, L, A>>
  for -x: W.Workspace<I, L, A>
  for h: {W.Workspace.find(~I, ~eqI, L, A, i, xs) == Some{x} : Maybe<&2, W.Workspace<I, L, A>>}
  {eqI(i, W.Workspace.tag(I, L, A, x)) == True{} : Bool}

def find_hit(I, eqI, L, A, i, xs, x, h):
  match xs:
    case Nil{}:
      ex_falso({eqI(i, W.Workspace.tag(I, L, A, x)) == True{} : Bool}, none_clash(W.Workspace<I, L, A>, x, h))
    case +y <> rest:
      find_hit.c(I, eqI, L, A, i, y, rest, x, h2 => find_hit(I, eqI, L, A, i, rest, x, h2), eqI(i, W.Workspace.tag(I, L, A, y)), {==}, h)

# view i of a set whose current tag is i (by ==) is the set
law view_true:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for -i: I
  for -r: W.StackSet<I, L, A, S, D>
  for h: {eqI(i, W.currentTag(I, L, A, S, D, r)) == True{} : Bool}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, r) == r : W.StackSet<I, L, A, S, D>}

def view_true(I, eqI, S, eqS, L, A, D, i, r, h):
  %Equal.sym(Bool, eqI(i, W.currentTag(I, L, A, S, D, r)), True{}, h) : {W.view.cur(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, r) == r : W.StackSet<I, L, A, S, D>}
  {==}

# else view looks among the visible screens
law view_false:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for -i: I
  for -s: W.StackSet<I, L, A, S, D>
  for h: {eqI(i, W.currentTag(I, L, A, S, D, s)) == False{} : Bool}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s) == W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), i, s) : W.StackSet<I, L, A, S, D>}

def view_false(I, eqI, S, eqS, L, A, D, i, s, h):
  %Equal.sym(Bool, eqI(i, W.currentTag(I, L, A, S, D, s)), False{}, h) : {W.view.cur(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, s) == W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), i, s) : W.StackSet<I, L, A, S, D>}
  {==}

# a workspace brought in from the hidden ones, tagged i, is current: a second
# view i changes nothing
law view_hid_some:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for +i: I
  for s: W.StackSet<I, L, A, S, D>
  for -x: W.Workspace<I, L, A>
  for h: {eqI(i, W.Workspace.tag(I, L, A, x)) == True{} : Bool}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view.hid(~I, ~eqI, L, A, S, D, Some{x}, s)) == W.view.hid(~I, ~eqI, L, A, S, D, Some{x}, s) : W.StackSet<I, L, A, S, D>}

def view_hid_some(I, eqI, S, eqS, L, A, D, i, s, x, h):
  match s:
    case W.StackSet{W.Screen{w, sc, sd}, v, hh, fl}:
      view_true(I, eqI, S, eqS, L, A, D, i, W.StackSet{W.Screen{x, sc, sd}, v, w <> W.Workspace.delete(~I, ~eqI, L, A, W.Workspace.tag(I, L, A, x), hh), fl}, h)

# so is one brought in from a visible screen
law view_vis_some:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for +i: I
  for s: W.StackSet<I, L, A, S, D>
  for -x: W.Screen<I, L, A, S, D>
  for h: {eqI(i, W.Workspace.tag(I, L, A, W.Screen.workspace(I, L, A, S, D, x))) == True{} : Bool}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, Some{x}, i, s)) == W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, Some{x}, i, s) : W.StackSet<I, L, A, S, D>}

def view_vis_some(I, eqI, S, eqS, L, A, D, i, s, x, h):
  match s:
    case W.StackSet{c, v, hh, fl}:
      view_true(I, eqI, S, eqS, L, A, D, i, W.StackSet{x, c <> W.Screen.delete(~S, ~eqS, I, L, A, D, W.Screen.screen(I, L, A, S, D, x), v), hh, fl}, h)

# no workspace tagged i anywhere: view i changes nothing
law view_none:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for -i: I
  for -s: W.StackSet<I, L, A, S, D>
  for e: {eqI(i, W.currentTag(I, L, A, S, D, s)) == False{} : Bool}
  for em: {W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)) == None{} : Maybe<&2, W.Screen<I, L, A, S, D>>}
  for ek: {W.Workspace.find(~I, ~eqI, L, A, i, W.hidden(I, L, A, S, D, s)) == None{} : Maybe<&2, W.Workspace<I, L, A>>}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s) == s : W.StackSet<I, L, A, S, D>}

def view_none(I, eqI, S, eqS, L, A, D, i, s, e, em, ek):
  %Equal.sym(W.StackSet<I, L, A, S, D>, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s), W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), i, s), view_false(I, eqI, S, eqS, L, A, D, i, s, e)) : {_ == s : W.StackSet<I, L, A, S, D>}
  %Equal.sym(Maybe<&2, W.Screen<I, L, A, S, D>>, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), None{}, em) : {W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, s) == s : W.StackSet<I, L, A, S, D>}
  %Equal.sym(Maybe<&2, W.Workspace<I, L, A>>, W.Workspace.find(~I, ~eqI, L, A, i, W.hidden(I, L, A, S, D, s)), None{}, ek) : {W.view.hid(~I, ~eqI, L, A, S, D, _, s) == s : W.StackSet<I, L, A, S, D>}
  {==}

law view_idem.k:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for +i: I
  for +s: W.StackSet<I, L, A, S, D>
  for +e: {eqI(i, W.currentTag(I, L, A, S, D, s)) == False{} : Bool}
  for +em: {W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)) == None{} : Maybe<&2, W.Screen<I, L, A, S, D>>}
  for k: Maybe<&2, W.Workspace<I, L, A>>
  for +ek: {W.Workspace.find(~I, ~eqI, L, A, i, W.hidden(I, L, A, S, D, s)) == k : Maybe<&2, W.Workspace<I, L, A>>}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s)) == W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s) : W.StackSet<I, L, A, S, D>}

def view_idem.k(I, eqI, S, eqS, L, A, D, i, s, e, em, k, ek):
  match k:
    case None{}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s), s, view_none(I, eqI, S, eqS, L, A, D, i, s, e, em, ek)) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, _) == _ : W.StackSet<I, L, A, S, D>}
      view_none(I, eqI, S, eqS, L, A, D, i, s, e, em, ek)
    case Some{x}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s), W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), i, s), view_false(I, eqI, S, eqS, L, A, D, i, s, e)) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, _) == _ : W.StackSet<I, L, A, S, D>}
      %Equal.sym(Maybe<&2, W.Screen<I, L, A, S, D>>, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), None{}, em) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, s)) == W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, s) : W.StackSet<I, L, A, S, D>}
      %Equal.sym(Maybe<&2, W.Workspace<I, L, A>>, W.Workspace.find(~I, ~eqI, L, A, i, W.hidden(I, L, A, S, D, s)), Some{x}, ek) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view.hid(~I, ~eqI, L, A, S, D, _, s)) == W.view.hid(~I, ~eqI, L, A, S, D, _, s) : W.StackSet<I, L, A, S, D>}
      view_hid_some(I, eqI, S, eqS, L, A, D, i, s, x, find_hit(I, eqI, L, A, i, W.hidden(I, L, A, S, D, s), x, ek))

law view_idem.m:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for +i: I
  for +s: W.StackSet<I, L, A, S, D>
  for +e: {eqI(i, W.currentTag(I, L, A, S, D, s)) == False{} : Bool}
  for m: Maybe<&2, W.Screen<I, L, A, S, D>>
  for +em: {W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)) == m : Maybe<&2, W.Screen<I, L, A, S, D>>}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s)) == W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s) : W.StackSet<I, L, A, S, D>}

def view_idem.m(I, eqI, S, eqS, L, A, D, i, s, e, m, em):
  match m:
    case None{}:
      view_idem.k(I, eqI, S, eqS, L, A, D, i, s, e, em, W.Workspace.find(~I, ~eqI, L, A, i, W.hidden(I, L, A, S, D, s)), {==})
    case Some{x}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s), W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), i, s), view_false(I, eqI, S, eqS, L, A, D, i, s, e)) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, _) == _ : W.StackSet<I, L, A, S, D>}
      %Equal.sym(Maybe<&2, W.Screen<I, L, A, S, D>>, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), Some{x}, em) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, s)) == W.view.vis(~I, ~eqI, ~S, ~eqS, L, A, D, _, i, s) : W.StackSet<I, L, A, S, D>}
      view_vis_some(I, eqI, S, eqS, L, A, D, i, s, x, findTag_hit(I, eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s), x, em))

law view_idem.b:
  for ~I: Data
  for ~eqI: I -> I -> Bool
  for ~S: Data
  for ~eqS: S -> S -> Bool
  for -L: Data
  for -A: Data
  for -D: Data
  for +i: I
  for +s: W.StackSet<I, L, A, S, D>
  for b: Bool
  for +e: {eqI(i, W.currentTag(I, L, A, S, D, s)) == b : Bool}
  {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s)) == W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s) : W.StackSet<I, L, A, S, D>}

def view_idem.b(I, eqI, S, eqS, L, A, D, i, s, b, e):
  match b:
    case True{}:
      %Equal.sym(W.StackSet<I, L, A, S, D>, W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, s), s, view_true(I, eqI, S, eqS, L, A, D, i, s, e)) : {W.view(~I, ~eqI, ~S, ~eqS, L, A, D, i, _) == _ : W.StackSet<I, L, A, S, D>}
      view_true(I, eqI, S, eqS, L, A, D, i, s, e)
    case False{}:
      view_idem.m(I, eqI, S, eqS, L, A, D, i, s, e, W.Screen.findTag(~I, ~eqI, L, A, S, D, i, W.visible(I, L, A, S, D, s)), {==})

def Proposed.view_idem(I, eqI, S, eqS, L, A, D, i, s):
  view_idem.b(I, eqI, S, eqS, L, A, D, i, s, eqI(i, W.currentTag(I, L, A, S, D, s)), {==})

# Layouts
# -------

def Proposed.mirror_twice(r):
  match r:
    case L.Rectangle{x, y, w, h}:
      {==}

law max0:
  for m: Nat
  {Nat.max(m, 0n) == m : Nat}

def max0(m):
  match m:
    case 0n:
      {==}
    case 1n+k:
      {==}

# splitVertically's loop gives one rectangle more than its count
law pos_count:
  for m: Nat
  for r: L.Rectangle
  {List.length(&2, L.Rectangle, L.splitVertically.pos(m, r)) == 1n+m : Nat}

def pos_count(m, r):
  match m:
    case 0n:
      {==}
    case 1n+ +k:
      match r:
        case L.Rectangle{sx, sy, sw, +sh}:
          %pos_count(k, L.Rectangle{sx, U32.add(sy, U32.div(sh, U32.from_nat(1n+1n+k))), sw, U32.sub(sh, U32.div(sh, U32.from_nat(1n+1n+k)))}) : {List.length(&2, L.Rectangle, L.splitVertically.pos(1n+k, L.Rectangle{sx, sy, sw, sh})) == 1n+_ : Nat}
          {==}

def Proposed.splitVertically_count(n, r):
  match n:
    case 0n:
      {==}
    case 1n+ +m:
      %Equal.sym(Nat, Nat.max(m, 0n), m, max0(m)) : {List.length(&2, L.Rectangle, L.splitVertically.pos(m, r)) == 1n+_ : Nat}
      pos_count(m, r)

law pos_xw:
  for m: Nat
  for -x: U32
  for -y: U32
  for -w: U32
  for -h: U32
  {Proposed.Rect.xws(L.splitVertically.pos(m, L.Rectangle{x, y, w, h})) == Proposed.Rect.rep(1n+m, L.Rectangle{x, 0, w, 0}) : List<&2, L.Rectangle>}

def pos_xw(m, x, y, w, h):
  match m:
    case 0n:
      {==}
    case 1n+k:
      %pos_xw(k, x, U32.add(y, U32.div(h, U32.from_nat(1n+1n+k))), w, U32.sub(h, U32.div(h, U32.from_nat(1n+1n+k)))) : {Proposed.Rect.xws(L.splitVertically.pos(1n+k, L.Rectangle{x, y, w, h})) == L.Rectangle{x, 0, w, 0} <> _ : List<&2, L.Rectangle>}
      {==}

def Proposed.splitVertically_xw(m, x, y, w, h):
  pos_xw(m, x, y, w, h)

# turned, the y and height of each are the x and width before
law yh_mirror:
  for rs: List<&2, L.Rectangle>
  {Proposed.Rect.yhs(L.Rect.mirrorAll(rs)) == L.Rect.mirrorAll(Proposed.Rect.xws(rs)) : List<&2, L.Rectangle>}

def yh_mirror(rs):
  match rs:
    case Nil{}:
      {==}
    case L.Rectangle{a, b, c, d} <> rest:
      %yh_mirror(rest) : {Proposed.Rect.yhs(L.Rect.mirrorAll(L.Rectangle{a, b, c, d} <> rest)) == L.Rectangle{0, a, 0, c} <> _ : List<&2, L.Rectangle>}
      {==}

law mirror_rep:
  for n: Nat
  for +r: L.Rectangle
  {L.Rect.mirrorAll(Proposed.Rect.rep(n, r)) == Proposed.Rect.rep(n, L.mirrorRect(r)) : List<&2, L.Rectangle>}

def mirror_rep(n, r):
  match n:
    case 0n:
      {==}
    case 1n+k:
      %mirror_rep(k, r) : {L.Rect.mirrorAll(Proposed.Rect.rep(1n+k, r)) == L.mirrorRect(r) <> _ : List<&2, L.Rectangle>}
      {==}

def Proposed.splitHorizontally_yh(m, x, y, w, h):
  %Equal.sym(List<&2, L.Rectangle>, Proposed.Rect.yhs(L.Rect.mirrorAll(L.splitVertically(1n+m, L.Rectangle{y, x, h, w}))), L.Rect.mirrorAll(Proposed.Rect.xws(L.splitVertically(1n+m, L.Rectangle{y, x, h, w}))), yh_mirror(L.splitVertically(1n+m, L.Rectangle{y, x, h, w}))) : {_ == Proposed.Rect.rep(1n+m, L.Rectangle{0, y, 0, h}) : List<&2, L.Rectangle>}
  %Equal.sym(List<&2, L.Rectangle>, Proposed.Rect.xws(L.splitVertically(1n+m, L.Rectangle{y, x, h, w})), Proposed.Rect.rep(1n+m, L.Rectangle{y, 0, h, 0}), pos_xw(m, y, x, h, w)) : {L.Rect.mirrorAll(_) == Proposed.Rect.rep(1n+m, L.Rectangle{0, y, 0, h}) : List<&2, L.Rectangle>}
  mirror_rep(1n+m, L.Rectangle{y, 0, h, 0})

def Proposed.splitVerticallyBy_xw(f, r):
  match r:
    case L.Rectangle{x, y, w, h}:
      {==}

def Proposed.splitVerticallyBy_xw2(f, r):
  match r:
    case L.Rectangle{x, y, w, h}:
      {==}

def Proposed.splitHorizontallyBy_yh(f, r):
  match r:
    case L.Rectangle{x, y, w, h}:
      {==}

def Proposed.splitHorizontallyBy_yh2(f, r):
  match r:
    case L.Rectangle{x, y, w, h}:
      {==}

def Proposed.tile_fullscreen(f, r):
  {==}

def Proposed.run_none(A, l, r):
  match l:
    case L.Full{}:
      {==}
    case L.Tall{n, d, f}:
      {==}
    case L.Mirror{x}:
      {==}
    case L.Choose{s, a, b}:
      match s:
        case L.CL{}:
          {==}
        case L.CR{}:
          {==}

def Proposed.run_full(A, r, s):
  {==}

def Proposed.run_mirror(A, l, r, m):
  match m:
    case None{}:
      %Equal.sym(List<&2, L.Place<A>>, L.Layout.run(A, l, L.mirrorRect(r), None{}), Nil{}, Proposed.run_none(A, l, L.mirrorRect(r))) : {Nil{} == L.Place.mirror(A, _) : List<&2, L.Place<A>>}
      {==}
    case Some{s}:
      {==}

def Proposed.desc_mirror(l):
  {==}

def Proposed.desc_full():
  {==}

def Proposed.full_ignores(m):
  {==}

def Proposed.incmaster_tall(n, k, d, f):
  {==}

def Proposed.default_cycle():
  {==}

def Proposed.default_jump_full():
  {==}

# Tall places every window
# ------------------------

def disc(b: Bool) -> Type:
  match b:
    case True{}:
      Empty
    case False{}:
      Unit

law clash:
  for h: {False{} == True{} : Bool}
  Empty

def clash(h):
  %h : disc(_)
  Unit{}

def cmp.not_gt(c: Cmp) -> Type:
  match c:
    case LT{}:
      Unit
    case EQ{}:
      Unit
    case GT{}:
      Empty

law gt_clash:
  for -c: Cmp
  for h: {c == GT{} : Cmp}
  for u: cmp.not_gt(c)
  Empty

def gt_clash(c, h, u):
  %h : cmp.not_gt(_)
  u

law le_refl:
  for k: Nat
  {Nat.is_le(k, k) == True{} : Bool}

def le_refl(k):
  match k:
    case 0n:
      {==}
    case 1n+j:
      le_refl(j)

law le_max1:
  for k: Nat
  {Nat.is_le(k, Nat.max(k, 1n)) == True{} : Bool}

def le_max1(k):
  match k:
    case 0n:
      {==}
    case 1n+ +j:
      %Equal.sym(Nat, Nat.max(j, 0n), j, max0(j)) : {Nat.is_le(j, _) == True{} : Bool}
      le_refl(j)

law zip_len:
  for -A: Data
  for xs: List<&2, A>
  for ys: List<&2, L.Rectangle>
  for h: {Nat.is_le(List.length(&2, A, xs), List.length(&2, L.Rectangle, ys)) == True{} : Bool}
  {List.length(&2, L.Place<A>, L.Place.zip(A, xs, ys)) == List.length(&2, A, xs) : Nat}

def zip_len(A, xs, ys, h):
  match xs:
    case Nil{}:
      match ys:
        case Nil{}:
          {==}
        case y <> yt:
          {==}
    case x <> xt:
      match ys:
        case Nil{}:
          ex_falso({List.length(&2, L.Place<A>, L.Place.zip(A, x <> xt, Nil{})) == List.length(&2, A, x <> xt) : Nat}, clash(h))
        case y <> yt:
          %zip_len(A, xt, yt, h) : {1n+List.length(&2, L.Place<A>, L.Place.zip(A, xt, yt)) == 1n+_ : Nat}
          {==}

law len_append:
  for -A: Data
  for xs: List<&2, A>
  for -ys: List<&2, A>
  {List.length(&2, A, List.append(&2, A, xs, ys)) == Nat.add(List.length(&2, A, xs), List.length(&2, A, ys)) : Nat}

def len_append(A, xs, ys):
  match xs:
    case Nil{}:
      {==}
    case x <> rest:
      %len_append(A, rest, ys) : {1n+List.length(&2, A, List.append(&2, A, rest, ys)) == 1n+_ : Nat}
      {==}

# the second column: m windows before it, n - m rows in it, n in all
law sub_len:
  for n: Nat
  for m: Nat
  for r: L.Rectangle
  for h: {Nat.cmp(n, m) == GT{} : Cmp}
  {Nat.add(m, List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(n, m), r))) == n : Nat}

def sub_len(n, m, r, h):
  match n:
    case 0n:
      match m:
        case 0n:
          ex_falso({Nat.add(0n, List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(0n, 0n), r))) == 0n : Nat}, gt_clash(EQ{}, h, Unit{}))
        case 1n+q:
          ex_falso({Nat.add(1n+q, List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(0n, 1n+q), r))) == 0n : Nat}, gt_clash(LT{}, h, Unit{}))
    case 1n+a:
      match m:
        case 0n:
          pos_count(a, r)
        case 1n+b:
          %sub_len(a, b, r, h) : {1n+Nat.add(b, List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(a, b), r))) == 1n+_ : Nat}
          {==}

law max_pos:
  for n: Nat
  for -p: Nat
  for h: {Nat.cmp(n, 1n+p) == GT{} : Cmp}
  {n == Nat.max(n, 1n) : Nat}

def max_pos(n, p, h):
  match n:
    case 0n:
      ex_falso({0n == Nat.max(0n, 1n) : Nat}, gt_clash(LT{}, h, Unit{}))
    case 1n+a:
      %Equal.sym(Nat, Nat.max(a, 0n), a, max0(a)) : {1n+a == 1n+_ : Nat}
      {==}

law tile_count.gt:
  for +f: N.Rat
  for r: L.Rectangle
  for +p: Nat
  for +n: Nat
  for +e: {Nat.cmp(n, 1n+p) == GT{} : Cmp}
  {List.length(&2, L.Rectangle, L.tile.cols(N.Int.of(1n+p), n, L.splitHorizontallyBy(f, r))) == Nat.max(n, 1n) : Nat}

def tile_count.gt(f, r, p, n, e):
  match r:
    case L.Rectangle{+sx, +sy, +sw, +sh}:
      %Equal.sym(Nat, List.length(&2, L.Rectangle, List.append(&2, L.Rectangle, L.splitVertically.pos(p, L.Rectangle{sx, sy, L.Rect.scale(sw, f), sh}), L.splitVertically.int(N.Int.sub.nat(n, 1n+p), L.Rectangle{U32.add(sx, L.Rect.scale(sw, f)), sy, U32.sub(sw, L.Rect.scale(sw, f)), sh}))), Nat.add(List.length(&2, L.Rectangle, L.splitVertically.pos(p, L.Rectangle{sx, sy, L.Rect.scale(sw, f), sh})), List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(n, 1n+p), L.Rectangle{U32.add(sx, L.Rect.scale(sw, f)), sy, U32.sub(sw, L.Rect.scale(sw, f)), sh}))), len_append(L.Rectangle, L.splitVertically.pos(p, L.Rectangle{sx, sy, L.Rect.scale(sw, f), sh}), L.splitVertically.int(N.Int.sub.nat(n, 1n+p), L.Rectangle{U32.add(sx, L.Rect.scale(sw, f)), sy, U32.sub(sw, L.Rect.scale(sw, f)), sh}))) : {_ == Nat.max(n, 1n) : Nat}
      %Equal.sym(Nat, List.length(&2, L.Rectangle, L.splitVertically.pos(p, L.Rectangle{sx, sy, L.Rect.scale(sw, f), sh})), 1n+p, pos_count(p, L.Rectangle{sx, sy, L.Rect.scale(sw, f), sh})) : {Nat.add(_, List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(n, 1n+p), L.Rectangle{U32.add(sx, L.Rect.scale(sw, f)), sy, U32.sub(sw, L.Rect.scale(sw, f)), sh}))) == Nat.max(n, 1n) : Nat}
      %Equal.sym(Nat, Nat.add(1n+p, List.length(&2, L.Rectangle, L.splitVertically.int(N.Int.sub.nat(n, 1n+p), L.Rectangle{U32.add(sx, L.Rect.scale(sw, f)), sy, U32.sub(sw, L.Rect.scale(sw, f)), sh}))), n, sub_len(n, 1n+p, L.Rectangle{U32.add(sx, L.Rect.scale(sw, f)), sy, U32.sub(sw, L.Rect.scale(sw, f)), sh}, e)) : {_ == Nat.max(n, 1n) : Nat}
      max_pos(n, p, e)

law tile_count.c:
  for +f: N.Rat
  for +r: L.Rectangle
  for +p: Nat
  for +n: Nat
  for c: Cmp
  for +e: {Nat.cmp(n, 1n+p) == c : Cmp}
  {List.length(&2, L.Rectangle, L.tile(f, r, N.Int.of(1n+p), n)) == Nat.max(n, 1n) : Nat}

def tile_count.c(f, r, p, n, c, e):
  match c:
    case LT{}:
      %Equal.sym(Cmp, Nat.cmp(n, 1n+p), LT{}, e) : {List.length(&2, L.Rectangle, W.Bool.if(List<&2, L.Rectangle>, Bool.or(Cmp.is_le(_), False{}), q => L.splitVertically(n, r), q => L.tile.cols(N.Int.of(1n+p), n, L.splitHorizontallyBy(f, r)))) == Nat.max(n, 1n) : Nat}
      Proposed.splitVertically_count(n, r)
    case EQ{}:
      %Equal.sym(Cmp, Nat.cmp(n, 1n+p), EQ{}, e) : {List.length(&2, L.Rectangle, W.Bool.if(List<&2, L.Rectangle>, Bool.or(Cmp.is_le(_), False{}), q => L.splitVertically(n, r), q => L.tile.cols(N.Int.of(1n+p), n, L.splitHorizontallyBy(f, r)))) == Nat.max(n, 1n) : Nat}
      Proposed.splitVertically_count(n, r)
    case GT{}:
      %Equal.sym(Cmp, Nat.cmp(n, 1n+p), GT{}, e) : {List.length(&2, L.Rectangle, W.Bool.if(List<&2, L.Rectangle>, Bool.or(Cmp.is_le(_), False{}), q => L.splitVertically(n, r), q => L.tile.cols(N.Int.of(1n+p), n, L.splitHorizontallyBy(f, r)))) == Nat.max(n, 1n) : Nat}
      tile_count.gt(f, r, p, n, e)

def Proposed.tile_count(f, r, nm, n):
  match nm:
    case 0n:
      match n:
        case 0n:
          Proposed.splitVertically_count(0n, r)
        case 1n+a:
          Proposed.splitVertically_count(1n+a, r)
    case 1n+ +p:
      tile_count.c(f, r, p, n, Nat.cmp(n, 1n+p), {==})

law tile_fits:
  for +f: N.Rat
  for +r: L.Rectangle
  for nm: Nat
  for +k: Nat
  {Nat.is_le(k, List.length(&2, L.Rectangle, L.tile(f, r, N.Int.of(nm), k))) == True{} : Bool}

def tile_fits(f, r, nm, k):
  %Equal.sym(Nat, List.length(&2, L.Rectangle, L.tile(f, r, N.Int.of(nm), k)), Nat.max(k, 1n), Proposed.tile_count(f, r, nm, k)) : {Nat.is_le(k, _) == True{} : Bool}
  le_max1(k)

def Proposed.tall_count(A, nm, d, frac, r, s, h0, h1):
  %Equal.sym(Bool, N.Rat.is_eq(frac, L.Rat.zero()), False{}, h0) : {List.length(&2, L.Place<A>, L.Tall.pick(A, _, N.Rat.is_eq(frac, L.Rat.one()), L.Place.zip(A, W.Stack.integrate(A, s), L.tile(frac, r, N.Int.of(nm), List.length(&2, A, W.Stack.integrate(A, s)))), N.Int.of(nm))) == List.length(&2, A, W.Stack.integrate(A, s)) : Nat}
  %Equal.sym(Bool, N.Rat.is_eq(frac, L.Rat.one()), False{}, h1) : {List.length(&2, L.Place<A>, L.Tall.pick(A, False{}, _, L.Place.zip(A, W.Stack.integrate(A, s), L.tile(frac, r, N.Int.of(nm), List.length(&2, A, W.Stack.integrate(A, s)))), N.Int.of(nm))) == List.length(&2, A, W.Stack.integrate(A, s)) : Nat}
  zip_len(A, W.Stack.integrate(A, s), L.tile(frac, r, N.Int.of(nm), List.length(&2, A, W.Stack.integrate(A, s))), tile_fits(frac, r, nm, List.length(&2, A, W.Stack.integrate(A, s))))

def Proposed.nested_cycle():
  {==}

# The window manager
# ------------------

# U32's == is reflexive: Word.cmp of a word and itself is EQ, bit by bit.
law bool_cmp_refl:
  for +b: Bool
  {Bool.cmp(b, b) == EQ{} : Cmp}

def bool_cmp_refl(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

law word_cmp_refl:
  for n: Nat
  for +a: Word(n)
  {Word.cmp(n, a, a) == EQ{} : Cmp}

def word_cmp_refl(n, a):
  match n:
    case 0n:
      {==}
    case 1n+p:
      match a:
        case WCon{+h, +t}:
          %Equal.sym(Cmp, Word.cmp(p, t, t), EQ{}, word_cmp_refl(p, t)) : {Word.cmp.fin(h, h, _) == EQ{} : Cmp}
          bool_cmp_refl(h)

law u32_eq_refl:
  for +w: U32
  {U32.is_eq(w, w) == True{} : Bool}

def u32_eq_refl(w):
  match w:
    case U32{+x}:
      %Equal.sym(Cmp, Word.cmp(32n, x, x), EQ{}, word_cmp_refl(32n, x)) : {Cmp.is_eq(_) == True{} : Bool}
      {==}

def Proposed.handle_other(c, st):
  {==}

def Proposed.windows_ws(c, old, m, p, n, new, mouse):
  {==}

def Proposed.windows_numlock(c, old, m, p, n, new, mouse):
  {==}

# no floating windows: none placed as floating
law flt_none:
  for +r: L.Rectangle
  for +vis: List<&2, U32>
  for xs: List<&2, U32>
  {O.flt.places(r, Nil{}, vis, xs) == Nil{} : List<&2, L.Place<U32>>}

def flt_none(r, vis, xs):
  match xs:
    case Nil{}:
      {==}
    case w <> rest:
      flt_none(r, vis, rest)

# no floating windows and none shown before: the filter keeps every window
law keep_all:
  for xs: List<&2, U32>
  {W.List.keep(~U32, ~O.Excl, ~O.tiled.p, O.Excl{Nil{}, Nil{}}, xs) == xs : List<&2, U32>}

def keep_all(xs):
  match xs:
    case Nil{}:
      {==}
    case x <> rest:
      %keep_all(rest) : {W.List.keep(~U32, ~O.Excl, ~O.tiled.p, O.Excl{Nil{}, Nil{}}, x <> rest) == x <> _ : List<&2, U32>}
      {==}

law tiled_all:
  for +st: Maybe<&2, W.Stack<U32>>
  {O.tiled.stack(O.Excl{Nil{}, Nil{}}, st) == st : Maybe<&2, W.Stack<U32>>}

def tiled_all(st):
  match st:
    case None{}:
      {==}
    case Some{s}:
      match s:
        case W.Stack{+f, +ls, +rs}:
          %Equal.sym(List<&2, U32>, W.List.keep(~U32, ~O.Excl, ~O.tiled.p, O.Excl{Nil{}, Nil{}}, f <> rs), f <> rs, keep_all(f <> rs)) : {W.Stack.filter.down(U32, _, W.List.keep(~U32, ~O.Excl, ~O.tiled.p, O.Excl{Nil{}, Nil{}}, ls)) == Some{W.Stack{f, ls, rs}} : Maybe<&2, W.Stack<U32>>}
          %Equal.sym(List<&2, U32>, W.List.keep(~U32, ~O.Excl, ~O.tiled.p, O.Excl{Nil{}, Nil{}}, ls), ls, keep_all(ls)) : {W.Stack.filter.down(U32, f <> rs, _) == Some{W.Stack{f, ls, rs}} : Maybe<&2, W.Stack<U32>>}
          {==}

def Proposed.one_screen_tiles(t, l, sid, r, st):
  %Equal.sym(List<&2, L.Place<U32>>, O.flt.places(r, Nil{}, Nil{}, W.Stack.integrate.maybe(U32, st)), Nil{}, flt_none(r, Nil{}, W.Stack.integrate.maybe(U32, st))) : {[List.append(&2, L.Place<U32>, _, L.Layout.run(U32, l, r, O.tiled.stack(O.Excl{Nil{}, Nil{}}, st)))] == [L.Layout.run(U32, l, r, st)] : List<&2, List<&2, L.Place<U32>>>}
  %Equal.sym(Maybe<&2, W.Stack<U32>>, O.tiled.stack(O.Excl{Nil{}, Nil{}}, st), st, tiled_all(st)) : {[L.Layout.run(U32, l, r, _)] == [L.Layout.run(U32, l, r, st)] : List<&2, List<&2, L.Place<U32>>>}
  {==}

def Proposed.key_focusDown():
  {==}

def Proposed.key_kill():
  {==}

def Proposed.key_nextLayout():
  {==}

def Proposed.key_quit():
  {==}

def Proposed.key_view3():
  {==}

def Proposed.key_shift9():
  {==}

def Proposed.cleanMask_locks():
  {==}

def Proposed.scan_override(w, m, s, rest):
  {==}

def Proposed.scan_viewable(w, s, rest):
  {==}

def Proposed.scan_iconic(w, rest):
  {==}

def Proposed.scan_withdrawn(w, rest):
  {==}

def Proposed.focusX_plain(s, pr, del, tf, w, t):
  {==}

def Proposed.focusX_noinput(s, pr, del, tf, w, t):
  {==}

def Proposed.focusX_takeFocus(s, pr, del, tf, w, t):
  %Equal.sym(Bool, U32.is_eq(tf, tf), True{}, u32_eq_refl(tf)) : {O.cmds.append([C.SetFocus{w}], Bool.pick(List<&2, C.Cmd>, Bool.or(_, False{}), [C.SendMessage{w, pr, tf, t}], Nil{})) == [C.SetFocus{w}, C.SendMessage{w, pr, tf, t}] : List<&2, C.Cmd>}
  {==}

def Proposed.kill_delete(s, pr, del, tf, w):
  %Equal.sym(Bool, U32.is_eq(del, del), True{}, u32_eq_refl(del)) : {Bool.pick(List<&2, C.Cmd>, Bool.or(_, False{}), [C.SendMessage{w, pr, del, 0}], [C.KillClient{w}]) == [C.SendMessage{w, pr, del, 0}] : List<&2, C.Cmd>}
  {==}

def Proposed.kill_client(s, pr, del, tf, w):
  {==}

def Proposed.not_fixed_without_hints():
  {==}

def Proposed.fixed_min_max(w, h):
  %Equal.sym(Bool, U32.is_eq(w, w), True{}, u32_eq_refl(w)) : {Bool.and(_, U32.is_eq(h, h)) == True{} : Bool}
  %Equal.sym(Bool, U32.is_eq(h, h), True{}, u32_eq_refl(h)) : {Bool.and(True{}, _) == True{} : Bool}
  {==}

def Proposed.contents_no_hints(w, h):
  {==}

def Proposed.pending_once(w):
  %Equal.sym(Bool, U32.is_eq(w, w), True{}, u32_eq_refl(w)) : {Bool.pick(Nat, _, 1n, 0n) == 1n : Nat}
  {==}
