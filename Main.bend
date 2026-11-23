# xmonad-bend: the window manager. The only part that talks to X: it reads
# X's events, asks X what xmonad asks about each, hands it to
# Operations.handle, and sends the requests it answers, in order.
#
# XMonad.Main's launch and its event loop. One def, wm, is the whole loop:
# while requests remain it sends the next (asking X first for the ones
# that need X's answers: FocusX, Kill, FloatWin, GrabKeys, Rescreen,
# Manage), and when none remain it waits for the next event. Bend asks
# every loop to end, so wm counts down a fuel of 10^14 steps (thousands of
# years of a window manager's use); Quit (mod-shift-q) ends it sooner.
#
# Build (x11.c needs libX11's headers and library on the C compiler's
# paths; flake.nix's shell sets them):
#
#   bend Main.bend -o xmonad-bend
#   DISPLAY=:1 ./xmonad-bend

import Base
import ./StackSet.bend as W
import ./Layout.bend as L
import ./Core.bend as C
import ./Operations.bend as O
import ./X.bend as X

# Decoding X's words ---------------------------------------------------------------

def attrs.of(ws: List<&2, U32>) -> Maybe<&2, C.Attrs>:
  match ws:
    case x <> y <> w <> h <> bw <> o <> _:
      Some{C.Attrs{x, y, w, h, bw, Bool.not(U32.is_zero(o))}}
    case _:
      None{}

def hints.of(ws: List<&2, U32>) -> C.Hints:
  match ws:
    case f <> a <> b <> c <> d <> e <> g <> h <> i <> j <> k <> l <> m <> _:
      C.Hints{f, a, b, c, d, e, g, h, i, j, k, l, m}
    case _:
      C.Hints.none()

def words.any(ws: List<&2, U32>) -> Bool:
  match ws:
    case Nil{}:
      False{}
    case _ <> _:
      True{}

def pixel.of(ws: List<&2, U32>) -> U32:
  match ws:
    case p <> _:
      p
    case Nil{}:
      0

def bool.of(+w: U32) -> Bool:
  Bool.not(U32.is_zero(w))

# An event and its time (CurrentTime, 0, for an event without one)
type Evt is Data:
  Evt{ev: C.Ev, time: U32}

def evt.other() -> Evt:
  Evt{C.EvOther{}, 0}

def decode.key(ws: List<&2, U32>) -> Evt:
  match ws:
    case m <> s <> t <> _:
      Evt{C.EvKey{m, s}, t}
    case _:
      evt.other()

def decode.button(ws: List<&2, U32>) -> Evt:
  match ws:
    case w <> b <> m <> s <> x <> y <> t <> _:
      Evt{C.EvButton{w, b, m, s, x, y}, t}
    case _:
      evt.other()

def decode.enter(ws: List<&2, U32>, p: List<&2, U32>) -> Evt:
  match ws p:
    case w <> m <> x <> y <> t <> _ _ <> _ <> ch <> _:
      Evt{C.EvEnter{w, U32.is_zero(m), x, y, ch}, t}
    case w <> m <> x <> y <> t <> _ _:
      Evt{C.EvEnter{w, U32.is_zero(m), x, y, 0}, t}
    case _ _:
      evt.other()

def decode.leave(ws: List<&2, U32>) -> Evt:
  match ws:
    case w <> s <> t <> _:
      Evt{C.EvLeave{w, bool.of(s)}, t}
    case _:
      evt.other()

def decode.destroy(ws: List<&2, U32>) -> Evt:
  match ws:
    case w <> _:
      Evt{C.EvDestroy{w}, 0}
    case _:
      evt.other()

def decode.unmap(ws: List<&2, U32>) -> Evt:
  match ws:
    case w <> s <> _:
      Evt{C.EvUnmap{w, bool.of(s)}, 0}
    case _:
      evt.other()

def decode.confnotify(ws: List<&2, U32>) -> Evt:
  match ws:
    case w <> _:
      Evt{C.EvConfigureNotify{w}, 0}
    case _:
      evt.other()

def decode.confreq(ws: List<&2, U32>, a: List<&2, U32>) -> Evt:
  match ws:
    case w <> vm <> x <> y <> wd <> ht <> bw <> ab <> dt <> _:
      Evt{C.EvConfigureRequest{w, vm, x, y, wd, ht, bw, ab, dt, attrs.of(a)}, 0}
    case _:
      evt.other()

def decode.mapping(ws: List<&2, U32>) -> Evt:
  match ws:
    case r <> _:
      Evt{C.EvMapping{r}, 0}
    case _:
      evt.other()

def decode.window(ws: List<&2, U32>) -> U32:
  match ws:
    case w <> _:
      w
    case Nil{}:
      0

# An event's words, with X's answers to what xmonad asks about it
def enrich.t(t: Nat, +rest: List<&2, U32>) -> IO(Evt):
  match t:
    case 2n:
      IO.pure(Evt, decode.key(rest))
    case 4n:
      IO.pure(Evt, decode.button(rest))
    case 7n:
      do IO<Evt>:
        p : List<&2, U32> <- X.pointer()
        IO.pure(Evt, decode.enter(rest, p))
    case 8n:
      IO.pure(Evt, decode.leave(rest))
    case 17n:
      IO.pure(Evt, decode.destroy(rest))
    case 18n:
      IO.pure(Evt, decode.unmap(rest))
    case 20n:
      +w = decode.window(rest)
      do IO<Evt>:
        a : List<&2, U32> <- X.attrs(w)
        h : List<&2, U32> <- X.normal_hints(w)
        tr : List<&2, U32> <- X.transient_for(w)
        IO.pure(Evt, Evt{C.EvMapRequest{w, attrs.of(a), hints.of(h), words.any(tr)}, 0})
    case 22n:
      IO.pure(Evt, decode.confnotify(rest))
    case 23n:
      do IO<Evt>:
        a : List<&2, U32> <- X.attrs(decode.window(rest))
        IO.pure(Evt, decode.confreq(rest, a))
    case 34n:
      IO.pure(Evt, decode.mapping(rest))
    case _:
      IO.pure(Evt, evt.other())

def enrich(ws: List<&2, U32>) -> IO(Evt):
  match ws:
    case t <> rest:
      enrich.t(U32.to_nat(t), rest)
    case Nil{}:
      IO.pure(Evt, evt.other())

# The loop ---------------------------------------------------------------------

# the requests left of the current event, its time, and the state
type Job is Data:
  Job{time: U32, step: C.Step}

def job.of(+c: C.Conf, st: C.XState, e: Evt) -> Job:
  match e:
    case Evt{ev, t}:
      Job{t, O.handle(c, st, ev)}

# the state with these requests before the rest
def job.then(+t: U32, s: C.Step, rest: List<&2, C.Cmd>) -> Job:
  match s:
    case C.Step{st, cs}:
      Job{t, C.Step{st, O.cmds.append(cs, rest)}}

def st.setNumlock(s: C.XState, n: U32) -> C.XState:
  match s:
    case C.XState{w, m, p, _}:
      C.XState{w, m, p, n}

# cacheNumlockMask, then grabKeys
def job.numlock(+t: U32, st: C.XState, +nl: U32, rest: List<&2, C.Cmd>) -> Job:
  Job{t, C.Step{st.setNumlock(st, nl), O.cmds.append(O.grabKeys(nl), rest)}}

def atoms.state(a: O.Atoms) -> U32:
  match a:
    case O.Atoms{s, _, _, _}:
      s

def rects.of(+ws: List<&2, U32>) -> List<&2, L.Rectangle>:
  match ws:
    case _ <> _ <> w <> h <> _:
      [L.Rectangle{0, 0, w, h}]
    case _:
      Nil{}

# manage at startup, of a window found by scan (if not already managed)
def manage.scan(+c: C.Conf, +st: C.XState, +w: U32, am: Maybe<&2, C.Attrs>, +h: C.Hints, tr: Bool) -> C.Step:
  W.Bool.if(C.Step, C.ws.member(w, O.st.ws(st)), _ => O.nop(st), _ => O.manage(c, st, w, am, h, tr))

def wm(fuel: Nat, +c: C.Conf, +a: O.Atoms, j: Job) -> IO(Unit):
  match fuel:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+k:
      match j:
        case Job{_, C.Step{+st, Nil{}}}:
          do IO<Unit>:
            ws : List<&2, U32> <- X.next()
            e : Evt <- enrich(ws)
            wm(k, c, a, job.of(c, st, e))
        case Job{+t, C.Step{+st, x <> +rest}}:
          match x:
            case C.SetWMState{+w, +v}:
              do IO<Unit>:
                r : U32 <- X.set_prop32(w, atoms.state(a), atoms.state(a), v, 0)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.SelectInput{+w, +m}:
              do IO<Unit>:
                r : U32 <- X.select_input(w, m)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.BorderWidth{+w, +b}:
              do IO<Unit>:
                r : U32 <- X.border_width(w, b)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.BorderColor{+w, +p}:
              do IO<Unit>:
                r : U32 <- X.border_color(w, p)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.MoveResize{+w, +x0, +y0, +w0, +h0}:
              do IO<Unit>:
                r : U32 <- X.move_resize(w, x0, y0, w0, h0)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.Raise{+w}:
              do IO<Unit>:
                r : U32 <- X.raise(w)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.StackBelow{+w, +s}:
              do IO<Unit>:
                r : U32 <- X.stack_below(w, s)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.MapWin{+w}:
              do IO<Unit>:
                r : U32 <- X.map(w)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.UnmapWin{+w}:
              do IO<Unit>:
                r : U32 <- X.unmap(w)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.ButtonGrab{+w, +on}:
              wm(k, c, a, Job{t, C.Step{st, O.cmds.append(O.buttonGrab(w, on), rest)}})
            case C.FocusX{+w}:
              do IO<Unit>:
                h : List<&2, U32> <- X.wm_hints(w)
                p : List<&2, U32> <- X.protocols(w)
                wm(k, c, a, Job{t, C.Step{st, O.cmds.append(O.focusX(a, w, t, h, p), rest)}})
            case C.Kill{+w}:
              do IO<Unit>:
                p : List<&2, U32> <- X.protocols(w)
                wm(k, c, a, Job{t, C.Step{st, O.cmds.append(O.kill(a, w, p), rest)}})
            case C.Spawn{+s}:
              do IO<Unit>:
                r : U32 <- X.spawn(s)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.Configure{+w, +vm, +x0, +y0, +w0, +h0, +b, +s, +m}:
              do IO<Unit>:
                r : U32 <- X.configure(w, vm, x0, y0, w0, h0, b, s, m)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.ConfigureNotify{+w, +x0, +y0, +w0, +h0, +b, +o}:
              do IO<Unit>:
                r : U32 <- X.configure_notify(w, x0, y0, w0, h0, b, Bool.pick(U32, o, 1, 0))
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.DropEvents{+m}:
              do IO<Unit>:
                r : U32 <- X.drop_events(m)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.Sync{}:
              do IO<Unit>:
                r : U32 <- X.sync()
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.GrabKeys{}:
              do IO<Unit>:
                ms : List<&2, U32> <- X.modifiers()
                wm(k, c, a, job.numlock(t, st, C.numlockMask(ms), rest))
            case C.FloatWin{+w}:
              do IO<Unit>:
                aw : List<&2, U32> <- X.attrs(w)
                hw : List<&2, U32> <- X.normal_hints(w)
                wm(k, c, a, job.then(t, O.float(c, st, w, attrs.of(aw), hints.of(hw)), rest))
            case C.Rescreen{}:
              do IO<Unit>:
                aw : List<&2, U32> <- X.attrs(O.conf.root(c))
                wm(k, c, a, job.then(t, O.rescreen(c, st, rects.of(aw)), rest))
            case C.Quit{}:
              IO.pure(Unit, Unit{})
            case C.SetFocus{+w}:
              do IO<Unit>:
                r : U32 <- X.set_focus(w)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.SendMessage{+w, +ty, +m0, +m1}:
              do IO<Unit>:
                r : U32 <- X.send_message(w, ty, m0, m1)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.KillClient{+w}:
              do IO<Unit>:
                r : U32 <- X.kill_client(w)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.GrabButton{+w, +b, +m, +o, +pm, +km}:
              do IO<Unit>:
                r : U32 <- X.grab_button(w, b, m, o, pm, km)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.UngrabButtons{+w}:
              do IO<Unit>:
                r : U32 <- X.ungrab_buttons(w)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.GrabKey{+m, +s}:
              do IO<Unit>:
                r : U32 <- X.grab_key(m, s)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.UngrabKeys{}:
              do IO<Unit>:
                r : U32 <- X.ungrab_keys()
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.GrabRootButtons{}:
              wm(k, c, a, Job{t, C.Step{st, O.cmds.append(O.grabButtons(O.conf.root(c), O.st.numlock(st)), rest)}})
            case C.Manage{+w}:
              do IO<Unit>:
                aw : List<&2, U32> <- X.attrs(w)
                hw : List<&2, U32> <- X.normal_hints(w)
                tr : List<&2, U32> <- X.transient_for(w)
                wm(k, c, a, job.then(t, manage.scan(c, st, w, attrs.of(aw), hints.of(hw), words.any(tr)), rest))

# Startup ------------------------------------------------------------------------

def fuel() -> Nat:
  Nat.mul(4000000000n, 25000n)

def manages(ws: List<&2, U32>) -> List<&2, C.Cmd>:
  match ws:
    case Nil{}:
      Nil{}
    case w <> rest:
      C.Manage{w} <> manages(rest)

def job.start(s: C.Step, found: List<&2, U32>) -> Job:
  match s:
    case C.Step{st, cs}:
      Job{0, C.Step{st, C.GrabKeys{} <> C.GrabRootButtons{} <> C.Sync{} <> O.cmds.append(cs, manages(found))}}

# launch, after the display and the windowset: grab the keys and buttons,
# show the (empty) windowset, then manage the windows already there
def launch(+c: C.Conf, +a: O.Atoms, m: Maybe<&2, C.WindowSet()>, found: List<&2, U32>) -> IO(Unit):
  match m:
    case None{}:
      IO.die(Unit, 1, "xmonad-bend: no workspaces or no screens")
    case Some{+s}:
      wm(fuel(), c, a, job.start(O.windows(c, O.initialState(s), s, False{}), found))

def main.start(r: List<&2, U32>) -> IO(Unit):
  match r:
    case +root <> +w <> +h <> _:
      do IO<Unit>:
        nb : List<&2, U32> <- X.color(C.cfg.normalBorderColor())
        fb : List<&2, U32> <- X.color(C.cfg.focusedBorderColor())
        s1 : U32 <- X.atom("WM_STATE")
        s2 : U32 <- X.atom("WM_PROTOCOLS")
        s3 : U32 <- X.atom("WM_DELETE_WINDOW")
        s4 : U32 <- X.atom("WM_TAKE_FOCUS")
        sc : List<&2, U32> <- X.scan(s1)
        s1b : U32 <- X.atom("WM_STATE")
        launch(C.Conf{root, pixel.of(nb), pixel.of(fb)}, O.Atoms{s1b, s2, s3, s4}, O.initialWinset([L.Rectangle{0, 0, w, h}]), O.scan.ok(sc))
    case _:
      IO.die(Unit, 1, "xmonad-bend: cannot open the display, or another window manager is running")

def main() -> IO(Unit):
  do IO<Unit>:
    r : List<&2, U32> <- X.open(C.cfg.rootMask())
    main.start(r)
