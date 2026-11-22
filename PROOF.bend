# The proofs of PROPOSED.bend. Nothing here is trusted: `bend PROOF.bend`
# checks every def, `--verdict` rechecks them with BendTT's kernel.

import Base
import ./StackSet.bend as W
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
