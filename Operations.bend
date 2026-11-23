# XMonad.Operations and XMonad.Main's event handler in Bend: what xmonad
# does with each event, as pure functions from the state (and X's answers)
# to the new state and the X requests to send (Core.bend's Step).
#
# What it means. windows f is xmonad's one way to change what is on the
# screen: it takes the windowset to f's, and sends X what it takes to show
# that: the new windows' borders and events, each visible screen's layout
# placed and stacked, the focused window's border and the input focus,
# every window no longer visible unmapped, every window gone withdrawn.
# manage, unmanage, focus, float and the key bindings are windows of a
# StackSet operation, as in Haskell; handle says which an event calls.
#
# Where this differs from XMonad.Operations (besides Core.bend's list):
# - windows renders a visible screen's workspace as it stands in the
#   windowset; Haskell takes the same workspace from W.view n ws (a view of
#   a shown tag moves no workspace).
# - setFocusX, killWindow and float need X's answers (WM_HINTS,
#   WM_PROTOCOLS, the window's attributes), so they come in two halves: the
#   Cmd, and a function here that Main.bend calls with the answers.
# - restackWindows is its requests: each window after the first stacked
#   just below the one before it (what Xlib's XRestackWindows sends).

import Base
import ./StackSet.bend as W
import ./Layout.bend as L
import ./Num.bend as N
import ./Core.bend as C

# Fields ----------------------------------------------------------------------

def st.ws(s: C.XState) -> C.WindowSet():
  match s:
    case C.XState{w, _, _, _}:
      w

def st.numlock(s: C.XState) -> U32:
  match s:
    case C.XState{_, _, _, n}:
      n

def st.setWs(s: C.XState, w: C.WindowSet()) -> C.XState:
  match s:
    case C.XState{_, m, p, n}:
      C.XState{w, m, p, n}

def conf.root(c: C.Conf) -> U32:
  match c:
    case C.Conf{r, _, _}:
      r

def conf.nbc(c: C.Conf) -> U32:
  match c:
    case C.Conf{_, n, _}:
      n

def conf.fbc(c: C.Conf) -> U32:
  match c:
    case C.Conf{_, _, f}:
      f

def nop(s: C.XState) -> C.Step:
  C.Step{s, Nil{}}

def step.cmds(s: C.Step) -> List<&2, C.Cmd>:
  match s:
    case C.Step{_, cs}:
      cs

def step.st(s: C.Step) -> C.XState:
  match s:
    case C.Step{x, _}:
      x

# xs ++ the step's requests
def step.after(xs: List<&2, C.Cmd>, s: C.Step) -> C.Step:
  match s:
    case C.Step{x, cs}:
      C.Step{x, List.append(&2, C.Cmd, xs, cs)}

def cmds.append(xs: List<&2, C.Cmd>, ys: List<&2, C.Cmd>) -> List<&2, C.Cmd>:
  List.append(&2, C.Cmd, xs, ys)

# setPixelSolid: the pixel with its alpha byte set
def pixel.solid(p: U32) -> U32:
  U32.or(p, 4278190080)

# Screens -----------------------------------------------------------------------

# the windows of each screen's workspace, in order
def scr.wins(xs: List<&2, C.WScreen()>) -> List<&2, U32>:
  match xs:
    case Nil{}:
      Nil{}
    case W.Screen{W.Workspace{_, _, st}, _, _} <> rest:
      List.append(&2, U32, W.Stack.integrate.maybe(U32, st), scr.wins(rest))

def scr.tags(xs: List<&2, C.WScreen()>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case W.Screen{W.Workspace{t, _, _}, _, _} <> rest:
      t <> scr.tags(rest)

def tag.elem(+t: String, ts: List<&2, String>) -> Bool:
  W.List.elem(~String, ~String.eq, t, ts)

# A layout after a message: unchanged if it does not answer it
def layout.after(+l: L.Layout, m: L.Msg) -> L.Layout:
  L.Layout.orig(L.handleMessage(l, m), l)

# sendMessageWithNoRefresh Hide to each hidden workspace whose tag was shown
def hideLayouts(+ts: List<&2, String>, hs: List<&2, C.WindowSpace()>) -> List<&2, C.WindowSpace()>:
  match hs:
    case Nil{}:
      Nil{}
    case W.Workspace{+t, +l, st} <> rest:
      W.Workspace{t, Bool.pick(L.Layout, tag.elem(t, ts), layout.after(l, L.Hide{}), l), st} <> hideLayouts(ts, rest)

def ws.hideLayouts(+ts: List<&2, String>, s: C.WindowSet()) -> C.WindowSet():
  match s:
    case W.StackSet{c, v, h, f}:
      W.StackSet{c, v, hideLayouts(ts, h), f}

# Placing ----------------------------------------------------------------------

# Integer views of X's positions (Int32 in a U32)
def int.of32(+u: U32) -> N.Int:
  Bool.pick(N.Int, U32.is_lt(u, 2147483648), N.Int.Pos{U32.to_nat(u)}, N.Int.Neg{U32.to_nat(U32.not(u))})

# scaleRationalRect: a floating window's place on a screen's rectangle
def scaleRationalRect(r: L.Rectangle, f: W.RationalRect) -> L.Rectangle:
  match r f:
    case L.Rectangle{sx, sy, +sw, +sh} W.RationalRect{rx, ry, rw, rh}:
      L.Rectangle{U32.add(sx, L.Rect.scale(sw, rx)), U32.add(sy, L.Rect.scale(sh, ry)), L.Rect.scale(sw, rw), L.Rect.scale(sh, rh)}

# what windows keeps out of a screen's tiling: the floating windows, and
# the windows of the screens before it
type Excl is Data:
  Excl{fl: List<&2, W.Float<U32>>, vis: List<&2, U32>}

def tiled.keep(k: Excl, +x: U32) -> Bool:
  match k:
    case Excl{fl, vis}:
      Bool.and(Maybe.is_none(&2, W.RationalRect, C.ws.floatLookup(x, fl)), Bool.not(C.win.elem(x, vis)))

# tiled.keep as filter takes it (each argument once)
def tiled.p(k: Excl, x: U32) -> Bool:
  tiled.keep(k, x)

def tiled.stack(+k: Excl, m: Maybe<&2, W.Stack<U32>>) -> Maybe<&2, W.Stack<U32>>:
  match m:
    case None{}:
      None{}
    case Some{s}:
      W.Stack.filter(~U32, ~Excl, ~tiled.p, k, s)

def flt.one(+r: L.Rectangle, +w: U32, m: Maybe<&2, W.RationalRect>, seen: Bool, rest: List<&2, L.Place<U32>>) -> List<&2, L.Place<U32>>:
  match m seen:
    case Some{f} False{}:
      L.Place{w, scaleRationalRect(r, f)} <> rest
    case _ _:
      rest

# the floating windows of a screen's workspace, in its order, not shown on a
# screen before it, at their places
def flt.places(+r: L.Rectangle, +fl: List<&2, W.Float<U32>>, +vis: List<&2, U32>, ws: List<&2, U32>) -> List<&2, L.Place<U32>>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      flt.one(r, w, C.ws.floatLookup(w, fl), C.win.elem(w, vis), flt.places(r, fl, vis, rest))

# each screen's windows and places: its floating windows, then its layout's
# (vis: the windows of the screens before it)
def place.screens(+fl: List<&2, W.Float<U32>>, xs: List<&2, C.WScreen()>, +vis: List<&2, U32>) -> List<&2, List<&2, L.Place<U32>>>:
  match xs:
    case Nil{}:
      Nil{}
    case W.Screen{W.Workspace{_, l, +st}, _, +r} <> rest:
      +ws = W.Stack.integrate.maybe(U32, st)
      List.append(&2, L.Place<U32>, flt.places(r, fl, vis, ws), L.Layout.run(U32, l, r, tiled.stack(Excl{fl, vis}, st))) <> place.screens(fl, rest, List.append(&2, U32, vis, ws))

def places.wins(ps: List<&2, L.Place<U32>>) -> List<&2, U32>:
  match ps:
    case Nil{}:
      Nil{}
    case L.Place{w, _} <> rest:
      w <> places.wins(rest)

# restackWindows: each window just below the one before it
def restack.go(ws: List<&2, U32>, +above: U32) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      C.StackBelow{w, above} <> restack.go(rest, w)

def restack(ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      restack.go(rest, w)

def restack.all(ss: List<&2, List<&2, L.Place<U32>>>) -> List<&2, C.Cmd>:
  match ss:
    case Nil{}:
      Nil{}
    case ps <> rest:
      cmds.append(restack(places.wins(ps)), restack.all(rest))

# tileWindow: the window inside its rectangle, its border outside
def tile.least(+bw2: U32, +x: U32) -> U32:
  Bool.pick(U32, U32.is_le(x, bw2), 1, U32.sub(x, bw2))

def tile.all(ps: List<&2, L.Place<U32>>) -> List<&2, C.Cmd>:
  match ps:
    case Nil{}:
      Nil{}
    case L.Place{w, L.Rectangle{x, y, rw, rh}} <> rest:
      +bw2 = U32.add(C.cfg.borderWidth(), C.cfg.borderWidth())
      C.MoveResize{w, x, y, tile.least(bw2, rw), tile.least(bw2, rh)} <> tile.all(rest)

# The windows' X state ---------------------------------------------------------------

# setInitialProperties
def initProps(+nbc: U32, ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      C.SetWMState{w, C.state.iconic()} <> C.SelectInput{w, C.cfg.clientMask()} <> C.BorderWidth{w, C.cfg.borderWidth()} <> C.BorderColor{w, nbc} <> initProps(nbc, rest)

def border.of(m: Maybe<&2, U32>, +p: U32) -> List<&2, C.Cmd>:
  match m:
    case None{}:
      Nil{}
    case Some{w}:
      [C.BorderColor{w, pixel.solid(p)}]

# reveal: WM_STATE normal and mapped
def reveal.cmds(ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      C.SetWMState{w, C.state.normal()} <> C.MapWin{w} <> reveal.cmds(rest)

# the mapped set after reveal: each client added once
def reveal.mapped(+s: C.WindowSet(), ws: List<&2, U32>, ms: List<&2, U32>) -> List<&2, U32>:
  match ws:
    case Nil{}:
      ms
    case +w <> rest:
      +ms2 = ms
      reveal.mapped(s, rest, Bool.pick(List<&2, U32>, Bool.and(C.ws.member(w, s), Bool.not(C.win.elem(w, ms2))), w <> ms2, ms2))

# hide: the windows of ws that are mapped (m0)
def hide.hits(+m0: List<&2, U32>, ws: List<&2, U32>) -> List<&2, U32>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      List.filter.put(U32, w, hide.hits(m0, rest), C.win.elem(w, m0))

def hide.cmds(ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case +w <> rest:
      C.SelectInput{w, U32.and(C.cfg.clientMask(), U32.not(C.ev.structureNotify()))} <> C.UnmapWin{w} <> C.SelectInput{w, C.cfg.clientMask()} <> C.SetWMState{w, C.state.iconic()} <> hide.cmds(rest)

# waitingUnmap: M.insertWith (+) w 1, M.lookup, M.update pred, M.delete
def pending.inc(+w: U32, ps: List<&2, C.Pending>) -> List<&2, C.Pending>:
  match ps:
    case Nil{}:
      [C.Pending{w, 1n}]
    case C.Pending{+x, +n} <> +rest:
      W.Bool.if(List<&2, C.Pending>, U32.is_eq(x, w), _ => C.Pending{x, 1n+n} <> rest, _ => C.Pending{x, n} <> pending.inc(w, rest))

def pending.incAll(ws: List<&2, U32>, ps: List<&2, C.Pending>) -> List<&2, C.Pending>:
  match ws:
    case Nil{}:
      ps
    case w <> rest:
      pending.incAll(rest, pending.inc(w, ps))

def pending.get(+w: U32, ps: List<&2, C.Pending>) -> Nat:
  match ps:
    case Nil{}:
      0n
    case C.Pending{x, n} <> rest:
      Bool.pick(Nat, U32.is_eq(x, w), n, pending.get(w, rest))

def pending.del(+w: U32, ps: List<&2, C.Pending>) -> List<&2, C.Pending>:
  match ps:
    case Nil{}:
      Nil{}
    case C.Pending{+x, +n} <> +rest:
      Bool.pick(List<&2, C.Pending>, U32.is_eq(x, w), rest, C.Pending{x, n} <> pending.del(w, rest))

def pending.pred(+x: U32, n: Nat, rest: List<&2, C.Pending>) -> List<&2, C.Pending>:
  match n:
    case 0n:
      rest
    case 1n+k:
      match k:
        case 0n:
          rest
        case 1n+j:
          C.Pending{x, 1n+j} <> rest

def pending.dec(+w: U32, ps: List<&2, C.Pending>) -> List<&2, C.Pending>:
  match ps:
    case Nil{}:
      Nil{}
    case C.Pending{+x, +n} <> +rest:
      W.Bool.if(List<&2, C.Pending>, U32.is_eq(x, w), _ => pending.pred(x, n, rest), _ => C.Pending{x, n} <> pending.dec(w, rest))

def withdraw.cmds(ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case w <> rest:
      C.SetWMState{w, C.state.withdrawn()} <> withdraw.cmds(rest)

# setButtonGrab True on each window of the shown workspaces
def grabs.on(ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case w <> rest:
      C.ButtonGrab{w, True{}} <> grabs.on(rest)

# setFocusX w's pure half: the shown workspaces' windows take clicks, w
# does not (unless it is the root), then X's focus
def setFocusX(+root: U32, s: C.WindowSet(), +w: U32) -> List<&2, C.Cmd>:
  cmds.append(grabs.on(scr.wins(C.ws.screens(s))), cmds.append(Bool.pick(List<&2, C.Cmd>, U32.is_eq(w, root), Nil{}, [C.ButtonGrab{w, False{}}]), [C.FocusX{w}]))

def topFocus(m: Maybe<&2, U32>, +root: U32) -> U32:
  match m:
    case None{}:
      root
    case Some{w}:
      w

# windows ------------------------------------------------------------------------

# windows f: the state taken to the windowset new (f's answer on the old
# one), and the requests that show it; mouse: the focus came from the
# mouse (then the EnterNotifys it causes are kept)
def windows(+c: C.Conf, st: C.XState, +new: C.WindowSet(), mouse: Bool) -> C.Step:
  match st:
    case C.XState{+old, mapped, waiting, nl}:
      +oldvisible = scr.wins(C.ws.screens(old))
      +newwindows = C.win.diff(C.ws.allWindows(new), C.ws.allWindows(old))
      +perScreen = place.screens(C.ws.floating(new), C.ws.screens(new), Nil{})
      +rects = List.concat(&2, L.Place<U32>, perScreen)
      +visible = places.wins(rects)
      +m1 = reveal.mapped(new, visible, mapped)
      +hidden = C.win.diff(C.win.nub(List.append(&2, U32, oldvisible, newwindows)), visible)
      +hits = hide.hits(m1, hidden)
      +s2 = ws.hideLayouts(scr.tags(C.ws.screens(old)), new)
      +cs1 = cmds.append(initProps(conf.nbc(c), newwindows), border.of(C.ws.peek(old), conf.nbc(c)))
      +cs2 = cmds.append(restack.all(perScreen), tile.all(rects))
      +cs3 = cmds.append(border.of(C.ws.peek(new), conf.fbc(c)), reveal.cmds(visible))
      +cs4 = setFocusX(conf.root(c), new, topFocus(C.ws.peek(new), conf.root(c)))
      +cs5 = cmds.append(hide.cmds(hits), withdraw.cmds(C.win.diff(C.ws.allWindows(old), C.ws.allWindows(new))))
      +cs6 = Bool.pick(List<&2, C.Cmd>, mouse, Nil{}, [C.DropEvents{C.ev.enterWindow()}])
      C.Step{C.XState{s2, C.win.diff(m1, hits), pending.incAll(hits, waiting), nl}, cmds.append(cs1, cmds.append(cs2, cmds.append(cs3, cmds.append(cs4, cmds.append(cs5, cs6)))))}

def windowsKey(+c: C.Conf, +st: C.XState, f: C.WindowSet() -> C.WindowSet()) -> C.Step:
  windows(c, st, f(st.ws(st)), False{})

def refresh(+c: C.Conf, +st: C.XState) -> C.Step:
  windows(c, st, st.ws(st), False{})

# Floating -----------------------------------------------------------------------

type Dim is Data:
  Dim{w: U32, h: U32}

def u32.max(+a: U32, +b: U32) -> U32:
  Bool.pick(U32, U32.is_lt(a, b), b, a)

def u32.min(+a: U32, +b: U32) -> U32:
  Bool.pick(U32, U32.is_lt(b, a), b, a)

def hint.on(+flags: U32, bit: U32) -> Bool:
  Bool.not(U32.is_zero(U32.and(flags, bit)))

# applyAspectHint
def hint.aspect(+mnx: U32, +mny: U32, +mxx: U32, +mxy: U32, d: Dim) -> Dim:
  match d:
    case Dim{+w, +h}:
      W.Bool.if(Dim, Bool.or(Bool.or(U32.is_lt(mnx, 1), U32.is_lt(mny, 1)), Bool.or(U32.is_lt(mxx, 1), U32.is_lt(mxy, 1))), _ => Dim{w, h}, _ => W.Bool.if(Dim, U32.is_gt(U32.mul(w, mxy), U32.mul(h, mxx)), _ => Dim{U32.div(U32.mul(h, mxx), mxy), h}, _ => W.Bool.if(Dim, U32.is_lt(U32.mul(w, mny), U32.mul(h, mnx)), _ => Dim{w, U32.div(U32.mul(w, mny), mnx)}, _ => Dim{w, h})))

# applyResizeIncHint
def hint.inc(+iw: U32, +ih: U32, d: Dim) -> Dim:
  match d:
    case Dim{+w, +h}:
      Bool.pick(Dim, Bool.and(U32.is_gt(iw, 0), U32.is_gt(ih, 0)), Dim{U32.sub(w, U32.mod(w, iw)), U32.sub(h, U32.mod(h, ih))}, Dim{w, h})

# applyMaxSizeHint
def hint.max(+mw: U32, +mh: U32, d: Dim) -> Dim:
  match d:
    case Dim{+w, +h}:
      Bool.pick(Dim, Bool.and(U32.is_gt(mw, 0), U32.is_gt(mh, 0)), Dim{u32.min(w, mw), u32.min(h, mh)}, Dim{w, h})

def hint.base(+on: Bool, +bw: U32, +bh: U32, sub: Bool, d: Dim) -> Dim:
  match d:
    case Dim{+w, +h}:
      Bool.pick(Dim, on, Bool.pick(Dim, sub, Dim{U32.sub(w, bw), U32.sub(h, bh)}, Dim{U32.add(w, bw), U32.add(h, bh)}), Dim{w, h})

# applySizeHints': base off, aspect, increments, base back on, maximum; each
# only if its flag is set (PMaxSize 32, PResizeInc 64, PAspect 128,
# PBaseSize 256)
def hints.apply(h: C.Hints, d: Dim) -> Dim:
  match h:
    case C.Hints{+fl, _, _, mxw, mxh, iw, ih, anx, any, axx, axy, +bw, +bh}:
      +d1 = hint.base(hint.on(fl, 256), bw, bh, True{}, d)
      +d2 = Bool.pick(Dim, hint.on(fl, 128), hint.aspect(anx, any, axx, axy, d1), d1)
      +d3 = Bool.pick(Dim, hint.on(fl, 64), hint.inc(iw, ih, d2), d2)
      +d4 = hint.base(hint.on(fl, 256), bw, bh, False{}, d3)
      Bool.pick(Dim, hint.on(fl, 32), hint.max(mxw, mxh, d4), d4)

# applySizeHintsContents
def hints.contents(h: C.Hints, w: U32, ht: U32) -> Dim:
  hints.apply(h, Dim{u32.max(1, w), u32.max(1, ht)})

# isFixedSizeOrTransient's first half: min and max sizes set and equal
def hints.fixed(h: C.Hints) -> Bool:
  match h:
    case C.Hints{+fl, mnw, mnh, mxw, mxh, _, _, _, _, _, _, _, _}:
      Bool.and(Bool.and(hint.on(fl, 16), hint.on(fl, 32)), Bool.and(U32.is_eq(mnw, mxw), U32.is_eq(mnh, mxh)))

def scr.rect(s: C.WScreen()) -> L.Rectangle:
  match s:
    case W.Screen{_, _, r}:
      r

def scr.id(s: C.WScreen()) -> Nat:
  match s:
    case W.Screen{_, i, _}:
      i

def scr.tag(s: C.WScreen()) -> String:
  match s:
    case W.Screen{W.Workspace{t, _, _}, _, _}:
      t

# pointWithin x y r (Positions: signed)
def pointWithin(+x: U32, +y: U32, r: L.Rectangle) -> Bool:
  match r:
    case L.Rectangle{+rx, +ry, rw, rh}:
      +ix = int.of32(x)
      +iy = int.of32(y)
      Bool.and(Bool.and(Bool.not(Cmp.is_lt(N.Int.cmp(ix, int.of32(rx)))), Cmp.is_lt(N.Int.cmp(ix, int.of32(U32.add(rx, rw))))), Bool.and(Bool.not(Cmp.is_lt(N.Int.cmp(iy, int.of32(ry)))), Cmp.is_lt(N.Int.cmp(iy, int.of32(U32.add(ry, rh))))))

# pointScreen: the first screen whose rectangle holds the point
def pointScreen(+x: U32, +y: U32, xs: List<&2, C.WScreen()>) -> Maybe<&2, C.WScreen()>:
  match xs:
    case Nil{}:
      None{}
    case +s <> rest:
      W.Bool.if(Maybe<&2, C.WScreen()>, pointWithin(x, y, scr.rect(s)), _ => Some{s}, _ => pointScreen(x, y, rest))

def rect.is_eq(a: L.Rectangle, b: L.Rectangle) -> Bool:
  match a b:
    case L.Rectangle{x, y, w, h} L.Rectangle{x2, y2, w2, h2}:
      Bool.and(Bool.and(U32.is_eq(x, x2), U32.is_eq(y, y2)), Bool.and(U32.is_eq(w, w2), U32.is_eq(h, h2)))

# (==) `on` fmap (screenRect . screenDetail)
def sr_eq(a: Maybe<&2, C.WScreen()>, b: Maybe<&2, C.WScreen()>) -> Bool:
  match a b:
    case None{} None{}:
      True{}
    case Some{x} Some{y}:
      rect.is_eq(scr.rect(x), scr.rect(y))
    case _ _:
      False{}

def scr.current(s: C.WindowSet()) -> C.WScreen():
  W.current(String, L.Layout, U32, Nat, L.Rectangle, s)

def scr.orCurrent(m: Maybe<&2, C.WScreen()>, c: C.WScreen()) -> C.WScreen():
  match m:
    case None{}:
      c
    case Some{x}:
      x

# a % b for a window's position against a screen's (b > 0)
def rat.over(n: N.Int, +d: U32) -> N.Rat:
  N.Rat.norm(N.Rat{n, Nat.sub(U32.to_nat(d), 1n)})

def rat.half(r: N.Rat) -> N.Rat:
  match r:
    case N.Rat{n, +d}:
      N.Rat{n, 1n+Nat.add(d, d)}

def rat.centered(+r: N.Rat) -> N.Rat:
  N.Rat.norm(N.Rat.sub(N.Rat{N.Int.of(1n), 1n}, rat.half(r)))

type Loc is Data:
  Loc{sc: Nat, rr: W.RationalRect}

def loc.rr(l: Loc) -> W.RationalRect:
  match l:
    case Loc{_, r}:
      r

def loc.sc(l: Loc) -> Nat:
  match l:
    case Loc{s, _}:
      s

def floatLocation.at(sr: L.Rectangle, sid: Nat, +x: U32, +y: U32, d: Dim, +bw: U32, near: Bool) -> Loc:
  match sr d:
    case L.Rectangle{sx, sy, +sw, +sh} Dim{w, h}:
      +rx = rat.over(N.Int.sub(int.of32(x), int.of32(sx)), sw)
      +ry = rat.over(N.Int.sub(int.of32(y), int.of32(sy)), sh)
      +rw = rat.over(N.Int.Pos{U32.to_nat(U32.add(w, U32.add(bw, bw)))}, sw)
      +rh = rat.over(N.Int.Pos{U32.to_nat(U32.add(h, U32.add(bw, bw)))}, sh)
      Loc{sid, Bool.pick(W.RationalRect, near, W.RationalRect{rx, ry, rw, rh}, W.RationalRect{rat.centered(rw), rat.centered(rh), rw, rh})}

# floatLocation w: the screen a window is on and its place there as
# fractions of the screen; managed: whether xmonad manages it
def floatLocation(+s: C.WindowSet(), am: Maybe<&2, C.Attrs>, +h: C.Hints, +managed: Bool) -> Loc:
  match am:
    case None{}:
      Loc{scr.id(scr.current(s)), W.RationalRect{N.Rat{N.Int.of(0n), 0n}, N.Rat{N.Int.of(0n), 0n}, N.Rat{N.Int.of(1n), 0n}, N.Rat{N.Int.of(1n), 0n}}}
    case Some{C.Attrs{+x, +y, w, ht, +bw, _}}:
      +point = pointScreen(x, y, C.ws.screens(s))
      +sc = scr.orCurrent(Bool.pick(Maybe<&2, C.WScreen()>, Bool.or(managed, sr_eq(point, Some{scr.current(s)})), point, None{}), scr.current(s))
      +sr = scr.rect(sc)
      floatLocation.at(sr, scr.id(sc), x, y, hints.contents(h, w, ht), bw, Bool.or(managed, sr_eq(point, Some{sc})))

# manage's adjust: a place off the screen is centred
def adjust(r: W.RationalRect) -> W.RationalRect:
  match r:
    case W.RationalRect{+x, +y, +w, +h}:
      +one = L.Rat.one()
      +zero = L.Rat.zero()
      Bool.pick(W.RationalRect, Bool.or(Bool.or(Cmp.is_gt(N.Rat.cmp(N.Rat.add(x, w), one)), Cmp.is_gt(N.Rat.cmp(N.Rat.add(y, h), one))), Bool.or(Cmp.is_lt(N.Rat.cmp(x, zero)), Cmp.is_lt(N.Rat.cmp(y, zero)))), W.RationalRect{rat.centered(w), rat.centered(h), w, h}, W.RationalRect{x, y, w, h})

# manage w: a new window into the current workspace, on top, focused;
# floating if its size is fixed or it is transient for another
def manage(+c: C.Conf, +st: C.XState, +w: U32, am: Maybe<&2, C.Attrs>, +h: C.Hints, transient: Bool) -> C.Step:
  +s = st.ws(st)
  +float = Bool.or(hints.fixed(h), transient)
  +rr = loc.rr(floatLocation(s, am, h, False{}))
  windows(c, st, Bool.pick(C.WindowSet(), float, C.ws.float(w, adjust(rr), C.ws.insertUp(w, C.ws.view(C.ws.currentTag(s), s))), C.ws.insertUp(w, s)), False{})

def unmanage(+c: C.Conf, +st: C.XState, +w: U32) -> C.Step:
  windows(c, st, C.ws.delete(w, st.ws(st)), False{})

def float.move.go(+w: U32, shown: Bool, f: Maybe<&2, U32>, sw: Maybe<&2, String>, +s: C.WindowSet()) -> C.WindowSet():
  match shown f sw:
    case True{} Some{fw} Some{t}:
      C.ws.focusWindow(fw, C.ws.shiftWin(t, w, s))
    case _ _ _:
      s

# float w, after floatLocation's answer: a window on a shown workspace moves
# to the workspace of the screen it is now over, keeping the focus
def float.move(+w: U32, +sc: Nat, +s: C.WindowSet(), t: Maybe<&2, String>) -> C.WindowSet():
  match t:
    case None{}:
      s
    case Some{i}:
      float.move.go(w, tag.elem(i, scr.tags(C.ws.screens(s))), C.ws.peek(s), C.ws.lookupWorkspace(sc, s), s)

def float(+c: C.Conf, +st: C.XState, +w: U32, am: Maybe<&2, C.Attrs>, +h: C.Hints) -> C.Step:
  +s = st.ws(st)
  +l = floatLocation(s, am, h, C.ws.member(w, s))
  windows(c, st, C.ws.float(w, loc.rr(l), float.move(w, loc.sc(l), s, C.ws.findTag(w, s))), False{})

# Focus --------------------------------------------------------------------------

type Pos is Data:
  Pos{x: U32, y: U32}

def maybe.is(+w: U32, m: Maybe<&2, U32>) -> Bool:
  match m:
    case None{}:
      False{}
    case Some{x}:
      U32.is_eq(x, w)

def focus.tag(m: Maybe<&2, C.WScreen()>) -> Maybe<&2, String>:
  match m:
    case None{}:
      None{}
    case Some{x}:
      Some{scr.tag(x)}

def focus.screen(m: Maybe<&2, Pos>, +s: C.WindowSet()) -> Maybe<&2, String>:
  match m:
    case None{}:
      None{}
    case Some{Pos{x, y}}:
      focus.tag(pointScreen(x, y, C.ws.screens(s)))

def focus.new(+c: C.Conf, +st: C.XState, +w: U32, mnew: Maybe<&2, String>, +curr: String) -> C.Step:
  match mnew:
    case None{}:
      nop(st)
    case Some{+n}:
      W.Bool.if(C.Step, Bool.and(U32.is_eq(w, conf.root(c)), Bool.not(String.eq(curr, n))), _ => windows(c, st, C.ws.view(n, st.ws(st)), True{}), _ => nop(st))

# focus w (from the mouse, at the pointer's position, if known)
def focus(+c: C.Conf, +st: C.XState, +w: U32, mpos: Maybe<&2, Pos>) -> C.Step:
  +s = st.ws(st)
  W.Bool.if(C.Step, Bool.and(C.ws.member(w, s), Bool.not(maybe.is(w, C.ws.peek(s)))), _ => windows(c, st, C.ws.focusWindow(w, s), True{}), _ => focus.new(c, st, w, focus.screen(mpos, s), C.ws.currentTag(s)))

# The focus's X half (FocusX), from the window's WM_HINTS [flags, input]
# and WM_PROTOCOLS: the input focus unless the window says it takes no
# input; WM_TAKE_FOCUS if it is among its protocols
type Atoms is Data:
  Atoms{state: U32, protocols: U32, delete: U32, takeFocus: U32}

def focusX.input(+w: U32, hints: List<&2, U32>) -> List<&2, C.Cmd>:
  match hints:
    case +fl <> inp <> _:
      Bool.pick(List<&2, C.Cmd>, Bool.or(Bool.and(hint.on(fl, 1), Bool.not(U32.is_zero(inp))), Bool.not(hint.on(fl, 1))), [C.SetFocus{w}], Nil{})
    case _:
      [C.SetFocus{w}]

def focusX(a: Atoms, +w: U32, +time: U32, hints: List<&2, U32>, ps: List<&2, U32>) -> List<&2, C.Cmd>:
  match a:
    case Atoms{_, pr, _, +tf}:
      cmds.append(focusX.input(w, hints), Bool.pick(List<&2, C.Cmd>, C.win.elem(tf, ps), [C.SendMessage{w, pr, tf, time}], Nil{}))

# killWindow's X half: WM_DELETE_WINDOW if the window takes it, else kill
# its client
def kill(a: Atoms, +w: U32, ps: List<&2, U32>) -> List<&2, C.Cmd>:
  match a:
    case Atoms{_, pr, +del, _}:
      Bool.pick(List<&2, C.Cmd>, C.win.elem(del, ps), [C.SendMessage{w, pr, del, 0}], [C.KillClient{w}])

# setButtonGrab: buttons 1-3 with any modifier (clickJustFocuses: the
# pointer runs on), or none
def buttonGrab(+w: U32, on: Bool) -> List<&2, C.Cmd>:
  +pm = Bool.pick(U32, C.cfg.clickJustFocuses(), C.grab.async(), C.grab.sync())
  Bool.pick(List<&2, C.Cmd>, on, [C.GrabButton{w, 1, C.mask.any(), 0, pm, C.grab.sync()}, C.GrabButton{w, 2, C.mask.any(), 0, pm, C.grab.sync()}, C.GrabButton{w, 3, C.mask.any(), 0, pm, C.grab.sync()}], [C.UngrabButtons{w}])

def grabKeys.go(gs: List<&2, C.Grab>) -> List<&2, C.Cmd>:
  match gs:
    case Nil{}:
      Nil{}
    case C.Grab{m, s} <> rest:
      C.GrabKey{m, s} <> grabKeys.go(rest)

# grabKeys, after cacheNumlockMask; grabButtons (the mouse bindings: here
# mod-button2)
def grabKeys(+nl: U32) -> List<&2, C.Cmd>:
  C.UngrabKeys{} <> grabKeys.go(C.keys.grabs(C.keys(), C.extraModifiers(nl)))

def grabButtons.go(+root: U32, es: List<&2, U32>) -> List<&2, C.Cmd>:
  match es:
    case Nil{}:
      Nil{}
    case e <> rest:
      C.GrabButton{root, 2, U32.or(C.cfg.modMask(), e), 0, C.grab.async(), C.grab.sync()} <> grabButtons.go(root, rest)

def grabButtons(+root: U32, +nl: U32) -> List<&2, C.Cmd>:
  C.UngrabButtons{root} <> grabButtons.go(root, C.extraModifiers(nl))

# Keys and messages ------------------------------------------------------------------

def ws.currentLayout(s: C.WindowSet()) -> L.Layout:
  match s:
    case W.StackSet{W.Screen{W.Workspace{_, l, _}, _, _}, _, _, _}:
      l

def ws.setCurrentLayout(l: L.Layout, s: C.WindowSet()) -> C.WindowSet():
  match s:
    case W.StackSet{W.Screen{W.Workspace{t, _, st}, sc, sd}, v, h, f}:
      W.StackSet{W.Screen{W.Workspace{t, l, st}, sc, sd}, v, h, f}

def sendMessage.go(+c: C.Conf, +st: C.XState, m: Maybe<&2, L.Layout>) -> C.Step:
  match m:
    case None{}:
      nop(st)
    case Some{l}:
      windows(c, st, ws.setCurrentLayout(l, st.ws(st)), False{})

# sendMessage: the current layout's answer, then a refresh, if it answers
def sendMessage(+c: C.Conf, +st: C.XState, m: L.Msg) -> C.Step:
  sendMessage.go(c, st, L.handleMessage(ws.currentLayout(st.ws(st)), m))

def withFocused(m: Maybe<&2, U32>, +st: C.XState, f: U32 -> C.Step) -> C.Step:
  match m:
    case None{}:
      nop(st)
    case Some{w}:
      f(w)

def onScreen(m: Maybe<&2, String>, +st: C.XState, f: String -> C.Step) -> C.Step:
  match m:
    case None{}:
      nop(st)
    case Some{t}:
      f(t)

def act.on(+c: C.Conf, +st: C.XState, +s: C.WindowSet(), a: C.Act) -> C.Step:
  match a:
    case C.ASpawn{cmd}:
      C.Step{st, [C.Spawn{cmd}]}
    case C.AKill{}:
      withFocused(C.ws.peek(s), st, w => C.Step{st, [C.Kill{w}]})
    case C.AMsg{m}:
      sendMessage(c, st, m)
    case C.ASetLayout{}:
      windows(c, st, ws.setCurrentLayout(C.cfg.layout(), s), False{})
    case C.ARefresh{}:
      refresh(c, st)
    case C.AFocusDown{}:
      windows(c, st, W.focusDown(String, L.Layout, U32, Nat, L.Rectangle, s), False{})
    case C.AFocusUp{}:
      windows(c, st, W.focusUp(String, L.Layout, U32, Nat, L.Rectangle, s), False{})
    case C.AFocusMaster{}:
      windows(c, st, W.focusMaster(String, L.Layout, U32, Nat, L.Rectangle, s), False{})
    case C.ASwapMaster{}:
      windows(c, st, W.swapMaster(String, L.Layout, U32, Nat, L.Rectangle, s), False{})
    case C.ASwapDown{}:
      windows(c, st, W.swapDown(String, L.Layout, U32, Nat, L.Rectangle, s), False{})
    case C.ASwapUp{}:
      windows(c, st, W.swapUp(String, L.Layout, U32, Nat, L.Rectangle, s), False{})
    case C.ASink{}:
      withFocused(C.ws.peek(s), st, w => windows(c, st, C.ws.sink(w, s), False{}))
    case C.AQuit{}:
      C.Step{st, [C.Quit{}]}
    case C.AGreedyView{t}:
      windows(c, st, C.ws.greedyView(t, s), False{})
    case C.AShift{t}:
      windows(c, st, C.ws.shift(t, s), False{})
    case C.AScreenView{i}:
      onScreen(C.ws.lookupWorkspace(i, s), st, t => windows(c, st, C.ws.view(t, s), False{}))
    case C.AScreenShift{i}:
      onScreen(C.ws.lookupWorkspace(i, s), st, t => windows(c, st, C.ws.shift(t, s), False{}))

def act(+c: C.Conf, +st: C.XState, a: C.Act) -> C.Step:
  act.on(c, st, st.ws(st), a)

def act.maybe(+c: C.Conf, +st: C.XState, m: Maybe<&2, C.Act>) -> C.Step:
  match m:
    case None{}:
      nop(st)
    case Some{a}:
      act(c, st, a)

# the mouse binding mod-button2 on the root: focus the window under the
# pointer and make it the master
def button.act(+c: C.Conf, +st: C.XState, +sub: U32) -> C.Step:
  windows(c, st, W.shiftMaster(String, L.Layout, U32, Nat, L.Rectangle, C.ws.focusWindow(sub, st.ws(st))), False{})

def button(+c: C.Conf, +st: C.XState, +w: U32, b: U32, m: U32, +sub: U32, +x: U32, +y: U32) -> C.Step:
  W.Bool.if(C.Step, Bool.and(U32.is_eq(w, conf.root(c)), Bool.and(U32.is_eq(C.cleanMask(st.numlock(st), m), C.cfg.modMask()), U32.is_eq(b, 2))), _ => button.act(c, st, sub), _ => focus(c, st, w, Some{Pos{x, y}}))

# Events -------------------------------------------------------------------------

def unmap.go(+c: C.Conf, +st: C.XState, +w: U32, syn: Bool) -> C.Step:
  match st:
    case C.XState{+s, +m, +p, +n}:
      W.Bool.if(C.Step, Bool.or(syn, Nat.is_eq(pending.get(w, p), 0n)), _ => unmanage(c, st, w), _ => nop(C.XState{s, m, pending.dec(w, p), n}))

def destroy.go(+c: C.Conf, +w: U32, s: C.Step) -> C.Step:
  match s:
    case C.Step{C.XState{ws, m, p, n}, cs}:
      C.Step{C.XState{ws, C.win.delete(w, m), pending.del(w, p), n}, cs}

def attrs.ovr(a: C.Attrs) -> Bool:
  match a:
    case C.Attrs{_, _, _, _, _, o}:
      o

def mapRequest(+c: C.Conf, +st: C.XState, +w: U32, am: Maybe<&2, C.Attrs>, +h: C.Hints, tr: Bool) -> C.Step:
  match am:
    case None{}:
      nop(st)
    case Some{+a}:
      W.Bool.if(C.Step, Bool.or(attrs.ovr(a), C.ws.member(w, st.ws(st))), _ => nop(st), _ => manage(c, st, w, Some{a}, h, tr))

def configure.notify(+w: U32, +bw: U32, am: Maybe<&2, C.Attrs>) -> List<&2, C.Cmd>:
  match am:
    case None{}:
      Nil{}
    case Some{C.Attrs{x, y, wd, ht, _, o}}:
      [C.ConfigureNotify{w, x, y, wd, ht, bw, o}]

def configureRequest(+c: C.Conf, +st: C.XState, +w: U32, +vm: U32, +x: U32, +y: U32, +wd: U32, +ht: U32, +bw: U32, +ab: U32, +dt: U32, am: Maybe<&2, C.Attrs>) -> C.Step:
  +s = st.ws(st)
  +mem = C.ws.member(w, s)
  W.Bool.if(C.Step, Bool.or(Maybe.is_some(&2, W.RationalRect, C.ws.floatLookup(w, C.ws.floating(s))), Bool.not(mem)), _ => C.Step{st, C.Configure{w, vm, x, y, wd, ht, C.cfg.borderWidth(), ab, dt} <> cmds.append(Bool.pick(List<&2, C.Cmd>, mem, [C.FloatWin{w}], Nil{}), [C.Sync{}])}, _ => C.Step{st, cmds.append(configure.notify(w, bw, am), [C.Sync{}])})

def enter(+c: C.Conf, +st: C.XState, +w: U32, normal: Bool, +x: U32, +y: U32, +child: U32) -> C.Step:
  W.Bool.if(C.Step, Bool.and(Bool.and(normal, C.cfg.focusFollowsMouse()), Bool.or(U32.is_zero(child), U32.is_eq(w, child))), _ => focus(c, st, w, Some{Pos{x, y}}), _ => nop(st))

def leave(+c: C.Conf, +st: C.XState, +w: U32, same: Bool) -> C.Step:
  W.Bool.if(C.Step, Bool.and(U32.is_eq(w, conf.root(c)), Bool.not(same)), _ => C.Step{st, setFocusX(conf.root(c), st.ws(st), conf.root(c))}, _ => nop(st))

# handle: what xmonad does with an event
def handle(+c: C.Conf, +st: C.XState, e: C.Ev) -> C.Step:
  match e:
    case C.EvKey{m, sym}:
      act.maybe(c, st, C.keys.find(C.cleanMask(st.numlock(st), m), sym, C.keys()))
    case C.EvMapRequest{w, am, h, tr}:
      mapRequest(c, st, w, am, h, tr)
    case C.EvDestroy{+w}:
      W.Bool.if(C.Step, C.ws.member(w, st.ws(st)), _ => destroy.go(c, w, unmanage(c, st, w)), _ => nop(st))
    case C.EvUnmap{+w, syn}:
      W.Bool.if(C.Step, C.ws.member(w, st.ws(st)), _ => unmap.go(c, st, w, syn), _ => nop(st))
    case C.EvMapping{+r}:
      Bool.pick(C.Step, Bool.or(U32.is_eq(r, 0), U32.is_eq(r, 1)), C.Step{st, [C.GrabKeys{}]}, nop(st))
    case C.EvButton{w, b, m, sub, x, y}:
      button(c, st, w, b, m, sub, x, y)
    case C.EvEnter{w, n, x, y, ch}:
      enter(c, st, w, n, x, y, ch)
    case C.EvLeave{w, same}:
      leave(c, st, w, same)
    case C.EvConfigureRequest{w, vm, x, y, wd, ht, bw, ab, dt, am}:
      configureRequest(c, st, w, vm, x, y, wd, ht, bw, ab, dt, am)
    case C.EvConfigureNotify{w}:
      Bool.pick(C.Step, U32.is_eq(w, conf.root(c)), C.Step{st, [C.Rescreen{}]}, nop(st))
    case C.EvOther{}:
      nop(st)

def rescreen.cons(s: C.WScreen(), p: List<&2, C.WScreen()> & List<&2, C.WindowSpace()>) -> List<&2, C.WScreen()> & List<&2, C.WindowSpace()>:
  match p:
    case (a, b):
      (s <> a, b)

# rescreen, from the screens' rectangles (the first is screen 0)
def rescreen.split(ws: List<&2, C.WindowSpace()>, rs: List<&2, L.Rectangle>, +i: Nat) -> List<&2, C.WScreen()> & List<&2, C.WindowSpace()>:
  match ws rs:
    case w <> wt r <> rt:
      rescreen.cons(W.Screen{w, i, r}, rescreen.split(wt, rt, 1n+i))
    case w <> wt Nil{}:
      (Nil{}, w <> wt)
    case Nil{} _:
      (Nil{}, Nil{})

def scr.workspaces(xs: List<&2, C.WScreen()>) -> List<&2, C.WindowSpace()>:
  match xs:
    case Nil{}:
      Nil{}
    case W.Screen{w, _, _} <> rest:
      w <> scr.workspaces(rest)

def rescreen.build(cur: C.WScreen(), p: List<&2, C.WScreen()> & List<&2, C.WindowSpace()>, f: List<&2, W.Float<U32>>) -> C.WindowSet():
  match p:
    case (vs, hs):
      W.StackSet{cur, vs, hs, f}

def rescreen.ws(rs: List<&2, L.Rectangle>, s: C.WindowSet()) -> C.WindowSet():
  match rs s:
    case r <> rt W.StackSet{W.Screen{cw, _, _}, v, h, f}:
      rescreen.build(W.Screen{cw, 0n, r}, rescreen.split(List.append(&2, C.WindowSpace(), scr.workspaces(v), h), rt, 1n), f)
    case Nil{} _:
      s

def rescreen(+c: C.Conf, +st: C.XState, rs: List<&2, L.Rectangle>) -> C.Step:
  windows(c, st, rescreen.ws(rs, st.ws(st)), False{})

# Startup -----------------------------------------------------------------------

# new layout (padToLen (length screens) workspaces) screens
def pad.go(ts: List<&2, String>, rs: List<&2, L.Rectangle>) -> List<&2, String>:
  match ts rs:
    case t <> tt _ <> rt:
      t <> pad.go(tt, rt)
    case t <> tt Nil{}:
      t <> tt
    case Nil{} _ <> rt:
      "" <> pad.go(Nil{}, rt)
    case Nil{} Nil{}:
      Nil{}

def initialWinset(+rs: List<&2, L.Rectangle>) -> Maybe<&2, C.WindowSet()>:
  W.new(String, L.Layout, U32, L.Rectangle, C.cfg.layout(), pad.go(C.cfg.workspaces(), rs), rs)

def initialState(s: C.WindowSet()) -> C.XState:
  C.XState{s, Nil{}, Nil{}, 0}

# scan: the root's children xmonad takes at startup: not override-redirect,
# and viewable (map_state 2) or iconic (WM_STATE 3)
def scan.ok(ws: List<&2, U32>) -> List<&2, U32>:
  match ws:
    case w <> o <> m <> s <> rest:
      List.filter.put(U32, w, scan.ok(rest), Bool.and(U32.is_zero(o), Bool.or(U32.is_eq(m, 2), U32.is_eq(s, 3))))
    case _:
      Nil{}
