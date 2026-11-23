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
import ./StateFile.bend as SF
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

# a String of X's bytes, a word each
def words.string(ws: List<&2, U32>) -> String:
  match ws:
    case Nil{}:
      ""
    case c <> rest:
      SCon{Char.from_u32(c), words.string(rest)}

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

def decode.motion(ws: List<&2, U32>) -> Evt:
  match ws:
    case x <> y <> _:
      Evt{C.EvMotion{x, y}, 0}
    case _:
      evt.other()

# a ButtonRelease's time (what the drag's end uses of it)
def decode.release(ws: List<&2, U32>) -> Evt:
  match ws:
    case _ <> _ <> _ <> _ <> _ <> _ <> t <> _:
      Evt{C.EvRelease{}, t}
    case _:
      Evt{C.EvRelease{}, 0}

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

# a ClientMessage: its window, then its message type
def decode.client(ws: List<&2, U32>) -> Evt:
  match ws:
    case _ <> m <> _:
      Evt{C.EvClientMessage{m}, 0}
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
    case 5n:
      IO.pure(Evt, decode.release(rest))
    case 6n:
      IO.pure(Evt, decode.motion(rest))
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
        cl : List<&2, U32> <- X.class_hint(w)
        IO.pure(Evt, Evt{C.EvMapRequest{w, attrs.of(a), hints.of(h), words.any(tr), words.string(cl)}, 0})
    case 22n:
      IO.pure(Evt, decode.confnotify(rest))
    case 23n:
      do IO<Evt>:
        a : List<&2, U32> <- X.attrs(decode.window(rest))
        IO.pure(Evt, decode.confreq(rest, a))
    case 33n:
      IO.pure(Evt, decode.client(rest))
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

# Directories and the state file ---------------------------------------------------

def env.of(r: Result<&1, &1, U32 & String, String>) -> Maybe<&2, String>:
  match r:
    case Done{v}:
      Some{v}
    case Fail{_}:
      None{}

# an environment variable, if set
def getEnv(name: String) -> IO(Maybe<&2, String>):
  do IO<Maybe<&2, String>>:
    r : Result<&1, &1, U32 & String, String> <- IO.get_env(name)
    IO.pure(Maybe<&2, String>, env.of(r))

def exists.of(r: Result<&1, &1, U32 & String, File>) -> IO(Bool):
  match r:
    case Done{f}:
      do IO<Bool>:
        Unit <- File.close(f)
        IO.pure(Bool, True{})
    case Fail{_}:
      IO.pure(Bool, False{})

# doesFileExist (a file that opens for reading)
def fileExists(path: String) -> IO(Bool):
  do IO<Bool>:
    r : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    exists.of(r)

def str.some(s: String) -> Bool:
  match s:
    case SNil{}:
      False{}
    case SCon{_, _}:
      True{}

# the directories on the way to a path, outermost first, then the path:
# "/a/b/c" gives "/a", "/a/b", "/a/b/c" (done: the part of it read)
def path.prefixes(s: String, +done: String) -> List<&2, String>:
  match s:
    case SNil{}:
      [done]
    case SCon{+ch, +rest}:
      W.Bool.if(List<&2, String>, Bool.and(U32.is_eq(Char.to_u32(ch), 47), str.some(done)), _ => done <> path.prefixes(rest, String.append(done, "/")), _ => path.prefixes(rest, String.append(done, SCon{ch, SNil{}})))

def mkdir.each(ps: List<&2, String>) -> IO(Unit):
  match ps:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case p <> rest:
      do IO<Unit>:
        r : U32 <- X.mkdir(p)
        mkdir.each(rest)

# createDirectoryIfMissing True
def mkdirs(+path: String) -> IO(Unit):
  mkdir.each(path.prefixes(path, ""))

# getXdgDirectory XdgData "xmonad": $XDG_DATA_HOME/xmonad, or (unset, or
# not an absolute path) ~/.local/share/xmonad
def dataDir.xdg(+home: String, x: Maybe<&2, String>) -> String:
  match x:
    case Some{SCon{+ch, rest}}:
      Bool.pick(String, U32.is_eq(Char.to_u32(ch), 47), String.append(SCon{ch, rest}, "/xmonad"), String.append(home, "/.local/share/xmonad"))
    case _:
      String.append(home, "/.local/share/xmonad")

def dataDir.pick(on: Bool, +xm: String, +xdg: String) -> IO(String):
  match on:
    case True{}:
      IO.pure(String, xm)
    case False{}:
      do IO<String>:
        Unit <- mkdirs(xdg)
        IO.pure(String, xdg)

def dataDir.home(+home: String) -> IO(String):
  +xm = String.append(home, "/.xmonad")
  do IO<String>:
    a : Bool <- fileExists(String.append(xm, "/xmonad.hs"))
    b : Bool <- fileExists(String.append(xm, "/build"))
    x : Maybe<&2, String> <- getEnv("XDG_DATA_HOME")
    dataDir.pick(Bool.or(a, b), xm, dataDir.xdg(home, x))

def str.or(m: Maybe<&2, String>, +d: String) -> String:
  match m:
    case Some{s}:
      s
    case None{}:
      d

def dataDir.getEnv(d: Maybe<&2, String>, c: Maybe<&2, String>, k: Maybe<&2, String>) -> IO(String):
  match d c k:
    case Some{x} Some{_} Some{_}:
      IO.pure(String, x)
    case _ _ _:
      do IO<String>:
        h : Maybe<&2, String> <- getEnv("HOME")
        dataDir.home(str.or(h, ""))

# getDirectories' dataDir: XMONAD_DATA_DIR, when XMONAD_CONFIG_DIR and
# XMONAD_CACHE_DIR are set too; else ~/.xmonad, if it has xmonad.hs or a
# build script; else the XDG one (made if missing; xmonad also makes the
# XDG config and cache directories, which xmonad-bend does not use)
def getDataDir(u: Unit) -> IO(String):
  do IO<String>:
    d : Maybe<&2, String> <- getEnv("XMONAD_DATA_DIR")
    c : Maybe<&2, String> <- getEnv("XMONAD_CONFIG_DIR")
    k : Maybe<&2, String> <- getEnv("XMONAD_CACHE_DIR")
    dataDir.getEnv(d, c, k)

# stateFileName
def state.path(d: String) -> String:
  String.append(d, "/xmonad.state")

def file.close(w: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  match w:
    case Tuple{f, _}:
      File.close(f)

def state.put(r: Result<&1, &1, U32 & String, File>, text: String) -> IO(Unit):
  match r:
    case Done{f}:
      do IO<Unit>:
        w : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, text)
        file.close(w)
    case Fail{_}:
      IO.pure(Unit, Unit{})

# writeFile path text, a failure ignored (catchIO)
def state.write(path: String, text: String) -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32 & String, File> <- File.open(path, "w")
    state.put(r, text)

# the rest of a file's text after acc, read a MiB at a time, then the file
# closed ("" if a read fails: it reads as no state)
def file.text(fuel: Nat, acc: String, r: File & Result<&1, &1, U32 & String, String>) -> IO(String):
  match fuel r:
    case 1n+f Tuple{file, Done{SCon{h, t}}}:
      do IO<String>:
        r2 : File & Result<&1, &1, U32 & String, String> <- File.read(file, 1048576)
        file.text(f, String.append(acc, SCon{h, t}), r2)
    case _ Tuple{file, Done{SNil{}}}:
      do IO<String>:
        Unit <- File.close(file)
        IO.pure(String, acc)
    case _ Tuple{file, _}:
      do IO<String>:
        Unit <- File.close(file)
        IO.pure(String, "")

def state.got(+path: String, r: Result<&1, &1, U32 & String, File>) -> IO(Maybe<&2, C.WindowSet()>):
  match r:
    case Done{f}:
      do IO<Maybe<&2, C.WindowSet()>>:
        r2 : File & Result<&1, &1, U32 & String, String> <- File.read(f, 1048576)
        text : String <- file.text(4096n, "", r2)
        u : U32 <- X.unlink(path)
        IO.pure(Maybe<&2, C.WindowSet()>, SF.read(text))
    case Fail{_}:
      IO.pure(Maybe<&2, C.WindowSet()>, None{})

# readStateFile, if the file is there: its windowset (None if it does not
# read), the file removed
def state.read(+path: String) -> IO(Maybe<&2, C.WindowSet()>):
  do IO<Maybe<&2, C.WindowSet()>>:
    r : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    state.got(path, r)

def program.of(as: List<String>) -> String:
  match as:
    case p <> _:
      p
    case Nil{}:
      "xmonad-bend"

# the program to run on a restart: this one, as it was invoked (xmonad
# runs "xmonad" from PATH, its launcher, which runs the user's build)
def getProgram(u: Unit) -> IO(String):
  do IO<String>:
    as : List<String> <- IO.args()
    IO.pure(String, program.of(as))

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
    case C.XState{w, m, p, _, d}:
      C.XState{w, m, p, n, d}

# cacheNumlockMask, then grabKeys
def job.numlock(+t: U32, st: C.XState, +nl: U32, rest: List<&2, C.Cmd>) -> Job:
  Job{t, C.Step{st.setNumlock(st, nl), O.cmds.append(O.grabKeys(nl), rest)}}

def atoms.state(a: O.Atoms) -> U32:
  match a:
    case O.Atoms{s, _, _, _}:
      s

# the root's rectangle, from its attributes
def rects.of(ws: List<&2, U32>) -> List<&2, L.Rectangle>:
  match ws:
    case x <> y <> w <> h <> _:
      [L.Rectangle{x, y, w, h}]
    case _:
      Nil{}

# X.xinerama's words, four to a rectangle
def rects.of4(ws: List<&2, U32>) -> List<&2, L.Rectangle>:
  match ws:
    case x <> y <> w <> h <> rest:
      L.Rectangle{x, y, w, h} <> rects.of4(rest)
    case _:
      Nil{}

# getScreenInfo: Xinerama's screens, or (none) the root's rectangle; then
# nubScreens (getCleanedScreenInfo)
def screens.of(xs: List<&2, U32>, root: List<&2, L.Rectangle>) -> List<&2, L.Rectangle>:
  match xs:
    case Nil{}:
      O.nubScreens(root)
    case x <> rest:
      O.nubScreens(rects.of4(x <> rest))

# manage at startup, of a window found by scan (if not already managed)
def manage.scan(+c: C.Conf, +st: C.XState, +w: U32, am: Maybe<&2, C.Attrs>, +h: C.Hints, tr: Bool, +cls: String) -> C.Step:
  W.Bool.if(C.Step, C.ws.member(w, O.st.ws(st)), _ => O.nop(st), _ => O.manage(c, st, w, am, h, tr, cls))

# mouseMoveWindow (then windows shiftMaster), from the window's attributes
# and the pointer's [x, y]
def job.mouseMove(+t: U32, +c: C.Conf, st: C.XState, +w: U32, aw: List<&2, U32>, p: List<&2, U32>, rest: List<&2, C.Cmd>) -> Job:
  match p:
    case x <> y <> _:
      job.then(t, O.mouseMove(c, st, w, attrs.of(aw), x, y), rest)
    case _:
      job.then(t, O.mouseMove(c, st, w, None{}, 0, 0), rest)

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
                xs : List<&2, U32> <- X.xinerama()
                aw : List<&2, U32> <- X.attrs(O.conf.root(c))
                wm(k, c, a, job.then(t, O.rescreen(c, st, screens.of(xs, rects.of(aw))), rest))
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
                cl : List<&2, U32> <- X.class_hint(w)
                wm(k, c, a, job.then(t, manage.scan(c, st, w, attrs.of(aw), hints.of(hw), words.any(tr), words.string(cl)), rest))
            case C.MoveWin{+w, +x0, +y0}:
              do IO<Unit>:
                r : U32 <- X.move(w, x0, y0)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.ResizeWin{+w, +w0, +h0}:
              do IO<Unit>:
                r : U32 <- X.resize(w, w0, h0)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.WarpPointer{+w, +x0, +y0}:
              do IO<Unit>:
                r : U32 <- X.warp(w, x0, y0)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.GrabPointer{+g}:
              do IO<Unit>:
                r : U32 <- X.grab_pointer(U32.or(C.ev.buttonRelease(), C.ev.pointerMotion()), g)
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.UngrabPointer{}:
              do IO<Unit>:
                r : U32 <- X.ungrab_pointer()
                wm(k, c, a, Job{t, C.Step{st, rest}})
            case C.MouseMove{+w}:
              do IO<Unit>:
                aw : List<&2, U32> <- X.attrs(w)
                p : List<&2, U32> <- X.pointer()
                wm(k, c, a, job.mouseMove(t, c, st, w, aw, p, rest))
            case C.MouseResize{+w}:
              do IO<Unit>:
                aw : List<&2, U32> <- X.attrs(w)
                hw : List<&2, U32> <- X.normal_hints(w)
                wm(k, c, a, job.then(t, O.mouseResize(c, st, w, attrs.of(aw), hints.of(hw)), rest))
            case C.Restart{}:
              do IO<Unit>:
                d : String <- getDataDir(Unit{})
                Unit <- state.write(state.path(d), SF.show(O.st.ws(st)))
                p : String <- getProgram(Unit{})
                r : U32 <- X.exec(p)
                wm(k, c, a, Job{t, C.Step{st, rest}})

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

# foldr W.delete s ws
def restore.del(ws: List<&2, U32>, s: C.WindowSet()) -> C.WindowSet():
  match ws:
    case Nil{}:
      s
    case w <> rest:
      C.ws.delete(w, restore.del(rest, s))

# the windowset to start with: the initial one, or the state file's less
# the windows that are no longer the root's children
def restored(s: C.WindowSet(), saved: Maybe<&2, C.WindowSet()>, +found: List<&2, U32>) -> C.WindowSet():
  match saved:
    case None{}:
      s
    case Some{+w}:
      restore.del(C.win.diff(C.ws.allWindows(w), found), w)

# launch, after the display, the windowset and the state file: grab the
# keys and buttons, show the windowset (the initial one, empty, or the
# state file's), then manage the windows already there and not in it
def launch(+c: C.Conf, +a: O.Atoms, m: Maybe<&2, C.WindowSet()>, saved: Maybe<&2, C.WindowSet()>, +found: List<&2, U32>) -> IO(Unit):
  match m:
    case None{}:
      IO.die(Unit, 1, "xmonad-bend: no workspaces or no screens")
    case Some{+s}:
      wm(fuel(), c, a, job.start(O.windows(c, O.initialState(s), restored(s, saved, found), False{}), found))

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
        s5 : U32 <- X.atom("XMONAD_RESTART")
        xs : List<&2, U32> <- X.xinerama()
        d : String <- getDataDir(Unit{})
        saved : Maybe<&2, C.WindowSet()> <- state.read(state.path(d))
        launch(C.Conf{root, pixel.of(nb), pixel.of(fb), s5}, O.Atoms{s1b, s2, s3, s4}, O.initialWinset(screens.of(xs, [L.Rectangle{0, 0, w, h}])), saved, O.scan.ok(sc))
    case _:
      IO.die(Unit, 1, "xmonad-bend: cannot open the display, or another window manager is running")

def main() -> IO(Unit):
  do IO<Unit>:
    r : List<&2, U32> <- X.open(C.cfg.rootMask())
    main.start(r)
