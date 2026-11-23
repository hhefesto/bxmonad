# X11, as xmonad-bend reaches it: each def one X request, query or event,
# done by x11.c (the C side). Nothing here decides anything; Main.bend
# says when each is used and Operations.bend what an event means.
#
# Words are U32s: a window, an atom and a pixel are X's 32-bit ids, a
# position is X's int in two's complement. A query answers a List of words,
# empty when X has no answer. x11.c's comments say what each answers.
#
# These are foreign effects, so a check names every def that uses them
# ("defs that depend on foreign effects"); the pure modules (StackSet,
# Layout, Num, Core, Operations) use none.

import Base

# the display ($DISPLAY), its root selecting mask's events: [root, width,
# height], or [] (no display, or another window manager)
def open(mask: U32) -> IO(List<&2, U32>):
  import "./x11.c"

# the modifier map: [modifier index, keysym] for each key in it
def modifiers() -> IO(List<&2, U32>):
  import "./x11.c"

def atom(name: String) -> IO(U32):
  import "./x11.c"

# [pixel] of a named color, or []
def color(name: String) -> IO(List<&2, U32>):
  import "./x11.c"

def grab_key(mask: U32, sym: U32) -> IO(U32):
  import "./x11.c"

def ungrab_keys() -> IO(U32):
  import "./x11.c"

def grab_button(win: U32, button: U32, mask: U32, owner: U32, pmode: U32, kmode: U32) -> IO(U32):
  import "./x11.c"

def ungrab_buttons(win: U32) -> IO(U32):
  import "./x11.c"

# the next event: its type, then its words (x11.c lists them)
def next() -> IO(List<&2, U32>):
  import "./x11.c"

# the root's children: [window, override_redirect, map_state, WM_STATE] each
def scan(wm_state: U32) -> IO(List<&2, U32>):
  import "./x11.c"

# [x, y, width, height, border_width, override_redirect, map_state], or []
def attrs(win: U32) -> IO(List<&2, U32>):
  import "./x11.c"

# [flags, min w, min h, max w, max h, inc w, inc h, min aspect x, y,
#  max aspect x, y, base w, base h]
def normal_hints(win: U32) -> IO(List<&2, U32>):
  import "./x11.c"

def transient_for(win: U32) -> IO(List<&2, U32>):
  import "./x11.c"

# WM_CLASS's class, a word per byte ([] if none)
def class_hint(win: U32) -> IO(List<&2, U32>):
  import "./x11.c"

# [flags, input]
def wm_hints(win: U32) -> IO(List<&2, U32>):
  import "./x11.c"

def protocols(win: U32) -> IO(List<&2, U32>):
  import "./x11.c"

# [root x, root y, child]
def pointer() -> IO(List<&2, U32>):
  import "./x11.c"

# Xinerama's screens, [x, y, width, height] each, or [] (none: no
# Xinerama)
def xinerama() -> IO(List<&2, U32>):
  import "./x11.c"

def select_input(win: U32, mask: U32) -> IO(U32):
  import "./x11.c"

def map(win: U32) -> IO(U32):
  import "./x11.c"

def unmap(win: U32) -> IO(U32):
  import "./x11.c"

def raise(win: U32) -> IO(U32):
  import "./x11.c"

def stack_below(win: U32, sibling: U32) -> IO(U32):
  import "./x11.c"

def move_resize(win: U32, x: U32, y: U32, w: U32, h: U32) -> IO(U32):
  import "./x11.c"

def move(win: U32, x: U32, y: U32) -> IO(U32):
  import "./x11.c"

def resize(win: U32, w: U32, h: U32) -> IO(U32):
  import "./x11.c"

# the pointer to x, y in win
def warp(win: U32, x: U32, y: U32) -> IO(U32):
  import "./x11.c"

# grab the pointer to the root for mask's events, showing the cursor
# font's glyph; and let it go
def grab_pointer(mask: U32, glyph: U32) -> IO(U32):
  import "./x11.c"

def ungrab_pointer() -> IO(U32):
  import "./x11.c"

def border_width(win: U32, w: U32) -> IO(U32):
  import "./x11.c"

def border_color(win: U32, pixel: U32) -> IO(U32):
  import "./x11.c"

def set_prop32(win: U32, prop: U32, ty: U32, a: U32, b: U32) -> IO(U32):
  import "./x11.c"

def set_focus(win: U32) -> IO(U32):
  import "./x11.c"

def send_message(win: U32, ty: U32, a: U32, b: U32) -> IO(U32):
  import "./x11.c"

def kill_client(win: U32) -> IO(U32):
  import "./x11.c"

def configure(win: U32, mask: U32, x: U32, y: U32, w: U32, h: U32, bw: U32, sib: U32, mode: U32) -> IO(U32):
  import "./x11.c"

def configure_notify(win: U32, x: U32, y: U32, w: U32, h: U32, bw: U32, ovr: U32) -> IO(U32):
  import "./x11.c"

def spawn(cmd: String) -> IO(U32):
  import "./x11.c"

def sync() -> IO(U32):
  import "./x11.c"

def drop_events(mask: U32) -> IO(U32):
  import "./x11.c"

# The rest is not X: the few system calls xmonad's restart and its state
# file need besides Bend's own (IO.get_env, File).

# mkdir(path) with mode 0777, less the umask: 0, or errno (EEXIST if it is
# there already)
def mkdir(path: String) -> IO(U32):
  import "./x11.c"

# unlink(path): 0, or errno
def unlink(path: String) -> IO(U32):
  import "./x11.c"

# the display flushed, then program run in this process's place with no
# arguments, found by PATH as execvp finds it (executeFile prog True []):
# it answers only when that fails (errno)
def exec(program: String) -> IO(U32):
  import "./x11.c"
