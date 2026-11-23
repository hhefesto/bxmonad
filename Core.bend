# XMonad.Core and XMonad.Config in Bend: the window manager's state, the
# events it hears and the X requests it makes, as plain data, and xmonad's
# default configuration.
#
# What it means. xmonad's X monad reads a configuration, keeps a state and
# talks to X. Here the talking is data: an event comes in as an Ev (with
# what X answered to the questions xmonad asks about it), and the pure
# functions of Operations.bend answer a Step, the new state and the list of
# requests (Cmd) to send, in order. Main.bend is the only part that talks to
# X; it sends the requests and feeds the events. So every decision xmonad
# makes is a function here, which can be stated, tested and proved about.
#
# Where this differs from XMonad.Core:
# - Windows, atoms and pixels are U32s (X's ids are 32 bits on the wire;
#   Haskell's Window is a Word64 holding one).
# - The windowset is StackSet<String, Layout, U32, Nat, Rectangle>: tags are
#   Strings, layouts the Layout type of Layout.bend, screen ids Nats, a
#   screen's detail its Rectangle (Haskell's ScreenDetail is a newtype of
#   one).
# - A request that needs X's answers to go on (setting the focus, killing a
#   window, floating one) is one Cmd; Main.bend asks X and finishes it, by
#   the same rules as xmonad (Operations.bend says which).
# - The configuration is xmonad's default (XMonad.Config), fixed: there is no
#   user config yet.

import Base
import ./StackSet.bend as W
import ./Layout.bend as L
import ./Num.bend as N

# X's numbers -------------------------------------------------------------------

def mask.shift() -> U32:
  1

def mask.lock() -> U32:
  2

def mask.mod1() -> U32:
  8

def mask.any() -> U32:
  32768

# event masks
def ev.keyPress() -> U32:
  1

def ev.buttonPress() -> U32:
  4

def ev.buttonRelease() -> U32:
  8

def ev.enterWindow() -> U32:
  16

def ev.leaveWindow() -> U32:
  32

def ev.pointerMotion() -> U32:
  64

def ev.structureNotify() -> U32:
  131072

def ev.substructureNotify() -> U32:
  524288

def ev.substructureRedirect() -> U32:
  1048576

def ev.propertyChange() -> U32:
  4194304

# WM_STATE's states
def state.withdrawn() -> U32:
  0

def state.normal() -> U32:
  1

def state.iconic() -> U32:
  3

# grab modes
def grab.sync() -> U32:
  0

def grab.async() -> U32:
  1

# the cursor font's glyphs the drags show (X11/cursorfont.h)
def cursor.fleur() -> U32:
  52

def cursor.bottomRightCorner() -> U32:
  14

# keysyms xmonad's keys use
def key.Return() -> U32:
  65293

def key.Tab() -> U32:
  65289

def key.space() -> U32:
  32

def key.comma() -> U32:
  44

def key.period() -> U32:
  46

def key.Num_Lock() -> U32:
  65407

def key.slash() -> U32:
  47

def key.question() -> U32:
  63

# a lowercase letter's keysym is its ASCII code: 'a' is 97
def key.letter(c: Char) -> U32:
  Char.to_u32(c)

# Data ------------------------------------------------------------------------

def WindowSet() -> Data:
  W.StackSet<String, L.Layout, U32, Nat, L.Rectangle>

def WindowSpace() -> Data:
  W.Workspace<String, L.Layout, U32>

def WScreen() -> Data:
  W.Screen<String, L.Layout, U32, Nat, L.Rectangle>

# A window's attributes (the ones xmonad reads)
type Attrs is Data:
  Attrs{x: U32, y: U32, w: U32, h: U32, bw: U32, ovr: Bool}

# WM_NORMAL_HINTS: flags say which of the rest are set
type Hints is Data:
  Hints{flags: U32, minw: U32, minh: U32, maxw: U32, maxh: U32, incw: U32, inch: U32, amnx: U32, amny: U32, amxx: U32, amxy: U32, basew: U32, baseh: U32}

def Hints.none() -> Hints:
  Hints{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

# An event, with X's answers to what xmonad asks about it
type Ev is Data:
  # a key pressed: its modifiers' mask and its keysym
  EvKey{mask: U32, sym: U32}
  # a button pressed on win (subwindow sub) at the root's x, y
  EvButton{win: U32, button: U32, mask: U32, sub: U32, x: U32, y: U32}
  # the pointer entered win; normal: NotifyNormal; child: the root's child
  # under the pointer (X.pointer)
  EvEnter{win: U32, normal: Bool, x: U32, y: U32, child: U32}
  EvLeave{win: U32, same: Bool}
  EvDestroy{win: U32}
  EvUnmap{win: U32, synthetic: Bool}
  # a client asks to be shown: its attributes (None: it is gone), hints,
  # whether it is transient for another, and its WM_CLASS's class ("" if
  # it has none)
  EvMapRequest{win: U32, attrs: Maybe<&2, Attrs>, hints: Hints, transient: Bool, cls: String}
  # a client asks to be moved or resized (its attributes: as for a map)
  EvConfigureRequest{win: U32, vmask: U32, x: U32, y: U32, w: U32, h: U32, bw: U32, above: U32, detail: U32, attrs: Maybe<&2, Attrs>}
  EvConfigureNotify{win: U32}
  EvMapping{request: U32}
  # a button released (only while a drag holds the pointer does xmonad
  # act on one)
  EvRelease{}
  # the pointer moved to the root's x, y (only while a drag holds it)
  EvMotion{x: U32, y: U32}
  # a ClientMessage, its message type (an atom): XMONAD_RESTART asks
  # xmonad to restart (xmonad --restart sends it to the root)
  EvClientMessage{kind: U32}
  EvOther{}

# A request to X (or to Main.bend, for the ones that need X's answers)
type Cmd is Data:
  SetWMState{win: U32, st: U32}
  SelectInput{win: U32, mask: U32}
  BorderWidth{win: U32, bw: U32}
  BorderColor{win: U32, pixel: U32}
  MoveResize{win: U32, x: U32, y: U32, w: U32, h: U32}
  Raise{win: U32}
  StackBelow{win: U32, sibling: U32}
  MapWin{win: U32}
  UnmapWin{win: U32}
  # setButtonGrab: on, buttons 1-3 with any modifier; off, none
  ButtonGrab{win: U32, on: Bool}
  # setFocusX's X part: the input focus by the window's WM_HINTS, and
  # WM_TAKE_FOCUS if it asks for it
  FocusX{win: U32}
  # killWindow: WM_DELETE_WINDOW if the window takes it, else XKillClient
  Kill{win: U32}
  Spawn{cmd: String}
  Configure{win: U32, vmask: U32, x: U32, y: U32, w: U32, h: U32, bw: U32, sibling: U32, mode: U32}
  ConfigureNotify{win: U32, x: U32, y: U32, w: U32, h: U32, bw: U32, ovr: Bool}
  # clearEvents mask
  DropEvents{mask: U32}
  Sync{}
  # cacheNumlockMask, then grabKeys
  GrabKeys{}
  # float: floatLocation needs the window's attributes and hints as they
  # are now, after the requests before it
  FloatWin{win: U32}
  # rescreen: the screens' rectangles
  Rescreen{}
  Quit{}
  # the X requests those come to
  SetFocus{win: U32}
  SendMessage{win: U32, ty: U32, a: U32, b: U32}
  KillClient{win: U32}
  GrabButton{win: U32, button: U32, mask: U32, owner: U32, pmode: U32, kmode: U32}
  UngrabButtons{win: U32}
  GrabKey{mask: U32, sym: U32}
  UngrabKeys{}
  # grabButtons (after GrabKeys has the numlock mask)
  GrabRootButtons{}
  # manage at startup: a window scan found (Main.bend asks X about it)
  Manage{win: U32}
  # moveWindow, resizeWindow, warpPointer (to x, y in win)
  MoveWin{win: U32, x: U32, y: U32}
  ResizeWin{win: U32, w: U32, h: U32}
  WarpPointer{win: U32, x: U32, y: U32}
  # mouseDrag's grab of the pointer (button releases and motion, to the
  # root) showing the cursor font's glyph, and its end
  GrabPointer{glyph: U32}
  UngrabPointer{}
  # mouseMoveWindow and mouseResizeWindow, then windows shiftMaster (the
  # mod-button1 and mod-button3 bindings after their focus): they need
  # the window's attributes and the pointer, or its WM_NORMAL_HINTS
  MouseMove{win: U32}
  MouseResize{win: U32}
  # restart "xmonad" True: the windowset written to the state file, then
  # the program run again in this one's place (Main.bend does both; if it
  # cannot be run, this one goes on)
  Restart{}

# A drag the pointer is grabbed for (xmonad's dragging): moving win, from
# its place wx, wy when the pointer was at ox, oy; or resizing it, its
# corner at wx, wy, by its WM_NORMAL_HINTS
type Drag is Data:
  DragMove{win: U32, wx: U32, wy: U32, ox: U32, oy: U32}
  DragResize{win: U32, wx: U32, wy: U32, hints: Hints}

# windows hidden by xmonad, with the UnmapNotifys still to come for each
type Pending is Data:
  Pending{win: U32, n: Nat}

type XState is Data:
  XState{ws: WindowSet(), mapped: List<&2, U32>, waiting: List<&2, Pending>, numlock: U32, drag: Maybe<&2, Drag>}

# what xmonad asked X for at startup: the root, the border colors' pixels
# and the XMONAD_RESTART atom
type Conf is Data:
  Conf{root: U32, nbc: U32, fbc: U32, restart: U32}

type Step is Data:
  Step{st: XState, cmds: List<&2, Cmd>}

# Configuration (XMonad.Config's defaults) ---------------------------------------

def cfg.workspaces() -> List<&2, String>:
  ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

def cfg.modMask() -> U32:
  mask.mod1()

def cfg.borderWidth() -> U32:
  1

def cfg.normalBorderColor() -> String:
  "gray"

def cfg.focusedBorderColor() -> String:
  "red"

def cfg.terminal() -> String:
  "xterm"

def cfg.focusFollowsMouse() -> Bool:
  True{}

def cfg.clickJustFocuses() -> Bool:
  True{}

# the manageHook: className =? "MPlayer" --> doFloat, className =? "mplayer2"
# --> doFloat (composeAll: a window of one of these classes floats)
def cfg.floatClasses() -> List<&2, String>:
  ["MPlayer", "mplayer2"]

def cfg.layout() -> L.Layout:
  L.Layout.default()

def cfg.clientMask() -> U32:
  U32.or(ev.structureNotify(), U32.or(ev.enterWindow(), ev.propertyChange()))

def cfg.rootMask() -> U32:
  U32.or(ev.substructureRedirect(), U32.or(ev.substructureNotify(), U32.or(ev.enterWindow(), U32.or(ev.leaveWindow(), U32.or(ev.structureNotify(), ev.buttonPress())))))

# What a key does
type Act is Data:
  ASpawn{cmd: String}
  AKill{}
  AMsg{m: L.Msg}
  ASetLayout{}
  ARefresh{}
  AFocusDown{}
  AFocusUp{}
  AFocusMaster{}
  ASwapMaster{}
  ASwapDown{}
  ASwapUp{}
  ASink{}
  AQuit{}
  AGreedyView{tag: String}
  AShift{tag: String}
  AScreenView{sc: Nat}
  AScreenShift{sc: Nat}

# XMonad.Config's help: the default bindings, as mod-shift-/ shows them
def help.lines() -> List<&2, String>:
  ["The default modifier key is 'alt'. Default keybindings:",
    "",
    "-- launching and killing programs",
    "mod-Shift-Enter  Launch xterminal",
    "mod-p            Launch dmenu",
    "mod-Shift-p      Launch gmrun",
    "mod-Shift-c      Close/kill the focused window",
    "mod-Space        Rotate through the available layout algorithms",
    "mod-Shift-Space  Reset the layouts on the current workSpace to default",
    "mod-n            Resize/refresh viewed windows to the correct size",
    "mod-Shift-/      Show this help message with the default keybindings",
    "",
    "-- move focus up or down the window stack",
    "mod-Tab        Move focus to the next window",
    "mod-Shift-Tab  Move focus to the previous window",
    "mod-j          Move focus to the next window",
    "mod-k          Move focus to the previous window",
    "mod-m          Move focus to the master window",
    "",
    "-- modifying the window order",
    "mod-Return   Swap the focused window and the master window",
    "mod-Shift-j  Swap the focused window with the next window",
    "mod-Shift-k  Swap the focused window with the previous window",
    "",
    "-- resizing the master/slave ratio",
    "mod-h  Shrink the master area",
    "mod-l  Expand the master area",
    "",
    "-- floating layer support",
    "mod-t  Push window back into tiling; unfloat and re-tile it",
    "",
    "-- increase or decrease number of windows in the master area",
    "mod-comma  (mod-,)   Increment the number of windows in the master area",
    "mod-period (mod-.)   Deincrement the number of windows in the master area",
    "",
    "-- quit, or restart",
    "mod-Shift-q  Quit xmonad",
    "mod-q        Restart xmonad",
    "",
    "-- Workspaces & screens",
    "mod-[1..9]         Switch to workSpace N",
    "mod-Shift-[1..9]   Move client to workspace N",
    "mod-{w,e,r}        Switch to physical/Xinerama screens 1, 2, or 3",
    "mod-Shift-{w,e,r}  Move client to screen 1, 2, or 3",
    "",
    "-- Mouse bindings: default actions bound to mouse events",
    "mod-button1  Set the window to floating mode and move by dragging",
    "mod-button2  Raise the window to the top of the stack",
    "mod-button3  Set the window to floating mode and resize by dragging"]

# unlines: each line and a newline
def unlines(xs: List<&2, String>) -> String:
  match xs:
    case Nil{}:
      ""
    case x <> rest:
      String.append(x, SCon{Char.from_u32(10), unlines(rest)})

def sh.quote.go(s: String) -> String:
  match s:
    case SNil{}:
      SCon{Char.from_u32(39), SNil{}}
    case SCon{+c, +t}:
      W.Bool.if(String, U32.is_eq(Char.to_u32(c), 39), _ => String.append("'\\''", sh.quote.go(t)), _ => SCon{c, sh.quote.go(t)})

# a word for /bin/sh: s in single quotes (a quote in it as '\'')
def sh.quote(s: String) -> String:
  SCon{Char.from_u32(39), sh.quote.go(s)}

# xmessage help, as a command for spawn's /bin/sh: XMONAD_XMESSAGE (if set)
# or xmessage, with xmonad's arguments, run in the shell's place
def help.cmd() -> String:
  String.append("exec \"${XMONAD_XMESSAGE-xmessage}\" -default okay -xrm '*international:true' -xrm '*fontSet:-*-fixed-medium-r-normal-*-18-*-*-*-*-*-*-*,-*-fixed-*-*-*-*-18-*-*-*-*-*-*-*,-*-*-*-*-*-*-18-*-*-*-*-*-*-*' ", sh.quote(unlines(help.lines())))

# mod-q: xmonad's restart command (with xmonad in PATH, it recompiles and
# restarts it: xmonad --restart asks the running window manager to)
def restart.cmd() -> String:
  "if type xmonad; then xmonad --recompile && xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi"

type Binding is Data:
  Binding{mask: U32, sym: U32, act: Act}

def keys.mod(m: U32) -> U32:
  U32.or(cfg.modMask(), m)

# mod-1..9: greedyView; mod-shift-1..9: shift (tags 1..9, keysyms '1'..'9')
def keys.tags(ts: List<&2, String>, +n: U32) -> List<&2, Binding>:
  match ts:
    case Nil{}:
      Nil{}
    case +t <> rest:
      Binding{keys.mod(0), n, AGreedyView{t}} <> Binding{keys.mod(mask.shift()), n, AShift{t}} <> keys.tags(rest, U32.add(n, 1))

def keys() -> List<&2, Binding>:
  +s = mask.shift()
  List.append(&2, Binding, [
    Binding{keys.mod(s), key.Return(), ASpawn{cfg.terminal()}},
    Binding{keys.mod(0), key.letter('p'), ASpawn{"dmenu_run"}},
    Binding{keys.mod(s), key.letter('p'), ASpawn{"gmrun"}},
    Binding{keys.mod(s), key.letter('c'), AKill{}},
    Binding{keys.mod(0), key.space(), AMsg{L.NextLayout{}}},
    Binding{keys.mod(s), key.space(), ASetLayout{}},
    Binding{keys.mod(0), key.letter('n'), ARefresh{}},
    Binding{keys.mod(0), key.Tab(), AFocusDown{}},
    Binding{keys.mod(s), key.Tab(), AFocusUp{}},
    Binding{keys.mod(0), key.letter('j'), AFocusDown{}},
    Binding{keys.mod(0), key.letter('k'), AFocusUp{}},
    Binding{keys.mod(0), key.letter('m'), AFocusMaster{}},
    Binding{keys.mod(0), key.Return(), ASwapMaster{}},
    Binding{keys.mod(s), key.letter('j'), ASwapDown{}},
    Binding{keys.mod(s), key.letter('k'), ASwapUp{}},
    Binding{keys.mod(0), key.letter('h'), AMsg{L.Shrink{}}},
    Binding{keys.mod(0), key.letter('l'), AMsg{L.Expand{}}},
    Binding{keys.mod(0), key.letter('t'), ASink{}},
    Binding{keys.mod(0), key.comma(), AMsg{L.IncMasterN{N.Int.of(1n)}}},
    Binding{keys.mod(0), key.period(), AMsg{L.IncMasterN{N.Int.Neg{0n}}}},
    Binding{keys.mod(s), key.letter('q'), AQuit{}},
    Binding{keys.mod(0), key.letter('q'), ASpawn{restart.cmd()}},
    Binding{keys.mod(s), key.slash(), ASpawn{help.cmd()}},
    Binding{keys.mod(0), key.question(), ASpawn{help.cmd()}},
    Binding{keys.mod(0), key.letter('w'), AScreenView{0n}},
    Binding{keys.mod(s), key.letter('w'), AScreenShift{0n}},
    Binding{keys.mod(0), key.letter('e'), AScreenView{1n}},
    Binding{keys.mod(s), key.letter('e'), AScreenShift{1n}},
    Binding{keys.mod(0), key.letter('r'), AScreenView{2n}},
    Binding{keys.mod(s), key.letter('r'), AScreenShift{2n}}], keys.tags(cfg.workspaces(), key.letter('1')))

# the action bound to (mask, sym), if any
def keys.find(+m: U32, +s: U32, ks: List<&2, Binding>) -> Maybe<&2, Act>:
  match ks:
    case Nil{}:
      None{}
    case Binding{km, ksym, a} <> rest:
      W.Bool.if(Maybe<&2, Act>, Bool.and(U32.is_eq(km, m), U32.is_eq(ksym, s)), _ => Some{a}, _ => keys.find(m, s, rest))

# What a mouse binding does to the window under the pointer
type MAct is Data:
  MMove{}
  MMaster{}
  MResize{}

type MBinding is Data:
  MBinding{mask: U32, button: U32, act: MAct}

# XMonad.Config's mouseBindings, in Map order: mod-button1 floats the window
# and moves it by dragging, mod-button2 raises it to the master,
# mod-button3 floats it and resizes it by dragging
def buttons() -> List<&2, MBinding>:
  [MBinding{keys.mod(0), 1, MMove{}}, MBinding{keys.mod(0), 2, MMaster{}}, MBinding{keys.mod(0), 3, MResize{}}]

# the action bound to (mask, button), if any
def buttons.find(+m: U32, +b: U32, bs: List<&2, MBinding>) -> Maybe<&2, MAct>:
  match bs:
    case Nil{}:
      None{}
    case MBinding{bm, bb, a} <> rest:
      W.Bool.if(Maybe<&2, MAct>, Bool.and(U32.is_eq(bm, m), U32.is_eq(bb, b)), _ => Some{a}, _ => buttons.find(m, b, rest))

# the (mask, keysym) pairs to grab: each key with each extra modifier
type Grab is Data:
  Grab{mask: U32, sym: U32}

def keys.grabs.one(+m: U32, +s: U32, es: List<&2, U32>) -> List<&2, Grab>:
  match es:
    case Nil{}:
      Nil{}
    case e <> rest:
      Grab{U32.or(m, e), s} <> keys.grabs.one(m, s, rest)

def keys.grabs(ks: List<&2, Binding>, +es: List<&2, U32>) -> List<&2, Grab>:
  match ks:
    case Nil{}:
      Nil{}
    case Binding{m, s, _} <> rest:
      List.append(&2, Grab, keys.grabs.one(m, s, es), keys.grabs(rest, es))

# extraModifiers: numlock and capslock, each on or off
def extraModifiers(+nl: U32) -> List<&2, U32>:
  [0, nl, mask.lock(), U32.or(nl, mask.lock())]

# cleanMask: a mask without numlock and capslock
def cleanMask(+nl: U32, m: U32) -> U32:
  U32.and(U32.not(U32.or(nl, mask.lock())), m)

# cacheNumlockMask: the bit of each modifier one of whose keys is Num_Lock,
# from X.modifiers' [modifier index, keysym] pairs
def numlockMask(ws: List<&2, U32>) -> U32:
  match ws:
    case i <> s <> rest:
      U32.or(Bool.pick(U32, U32.is_eq(s, key.Num_Lock()), U32.shln(1, U32.to_nat(i)), 0), numlockMask(rest))
    case _:
      0

# The windowset at U32 windows -------------------------------------------------

def ws.peek(s: WindowSet()) -> Maybe<&2, U32>:
  W.peek(String, L.Layout, U32, Nat, L.Rectangle, s)

def ws.member(+w: U32, s: WindowSet()) -> Bool:
  W.member(~U32, ~U32.is_eq, String, L.Layout, Nat, L.Rectangle, w, s)

def ws.findTag(+w: U32, s: WindowSet()) -> Maybe<&2, String>:
  W.findTag(~U32, ~U32.is_eq, String, L.Layout, Nat, L.Rectangle, w, s)

def ws.allWindows(s: WindowSet()) -> List<&2, U32>:
  W.allWindows(~U32, ~U32.is_eq, String, L.Layout, Nat, L.Rectangle, s)

def ws.index(s: WindowSet()) -> List<&2, U32>:
  W.index(String, L.Layout, U32, Nat, L.Rectangle, s)

def ws.screens(s: WindowSet()) -> List<&2, WScreen()>:
  W.screens(String, L.Layout, U32, Nat, L.Rectangle, s)

def ws.insertUp(+w: U32, +s: WindowSet()) -> WindowSet():
  W.insertUp(~U32, ~U32.is_eq, String, L.Layout, Nat, L.Rectangle, w, s)

def ws.delete(+w: U32, s: WindowSet()) -> WindowSet():
  W.delete(~U32, ~U32.cmp, String, L.Layout, Nat, L.Rectangle, w, s)

def ws.float(+w: U32, +r: W.RationalRect, s: WindowSet()) -> WindowSet():
  W.float(~U32, ~U32.cmp, String, L.Layout, Nat, L.Rectangle, w, r, s)

def ws.sink(+w: U32, s: WindowSet()) -> WindowSet():
  W.sink(~U32, ~U32.cmp, String, L.Layout, Nat, L.Rectangle, w, s)

def ws.view(+i: String, +s: WindowSet()) -> WindowSet():
  W.view(~String, ~String.eq, ~Nat, ~Nat.is_eq, L.Layout, U32, L.Rectangle, i, s)

def ws.greedyView(+i: String, +s: WindowSet()) -> WindowSet():
  W.greedyView(~String, ~String.eq, ~Nat, ~Nat.is_eq, L.Layout, U32, L.Rectangle, i, s)

def ws.shift(+i: String, +s: WindowSet()) -> WindowSet():
  W.shift(~String, ~String.eq, ~Nat, ~Nat.is_eq, ~U32, ~U32.is_eq, L.Layout, L.Rectangle, i, s)

def ws.shiftWin(+i: String, +w: U32, +s: WindowSet()) -> WindowSet():
  W.shiftWin(~String, ~String.eq, ~Nat, ~Nat.is_eq, ~U32, ~U32.is_eq, L.Layout, L.Rectangle, i, w, s)

def ws.focusWindow(+w: U32, +s: WindowSet()) -> WindowSet():
  W.focusWindow(~String, ~String.eq, ~Nat, ~Nat.is_eq, ~U32, ~U32.is_eq, L.Layout, L.Rectangle, w, s)

def ws.lookupWorkspace(+sc: Nat, s: WindowSet()) -> Maybe<&2, String>:
  W.lookupWorkspace(~Nat, ~Nat.is_eq, String, L.Layout, U32, L.Rectangle, sc, s)

def ws.currentTag(s: WindowSet()) -> String:
  W.currentTag(String, L.Layout, U32, Nat, L.Rectangle, s)

def ws.floating(s: WindowSet()) -> List<&2, W.Float<U32>>:
  W.floating(String, L.Layout, U32, Nat, L.Rectangle, s)

def ws.floatLookup(+w: U32, fs: List<&2, W.Float<U32>>) -> Maybe<&2, W.RationalRect>:
  W.Float.lookup(~U32, ~U32.cmp, w, fs)

def win.elem(+w: U32, xs: List<&2, U32>) -> Bool:
  W.List.elem(~U32, ~U32.is_eq, w, xs)

def win.diff(xs: List<&2, U32>, ys: List<&2, U32>) -> List<&2, U32>:
  W.List.diff(~U32, ~U32.is_eq, xs, ys)

def win.nub(xs: List<&2, U32>) -> List<&2, U32>:
  W.List.nub(~U32, ~U32.is_eq, xs)

def win.delete(+w: U32, xs: List<&2, U32>) -> List<&2, U32>:
  W.List.delete(~U32, ~U32.is_eq, w, xs)
