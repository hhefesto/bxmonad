// X11 for xmonad-bend
// ===================
//
// The X requests and events xmonad uses, each one Xlib call or a few, with
// no decisions in them: what to do with an event, and when to send a
// request, is decided in Bend (Operations.bend, Main.bend). X.bend declares
// each effect; this file is spliced into the program's C after Bend's
// runtime, and each entry is present only when its effect is reachable.
//
// Words cross as U32s. A window, an atom and a pixel are X's 32-bit ids; a
// position is X's int, in two's complement. A query answers a List of
// words, empty when X has no answer (the window is gone, the property is
// not set). An event is a List of words whose head is X's event type.
//
// One connection, opened by X.open and kept here: every other effect uses
// it. Errors from requests on windows that have gone away are expected (a
// window can close at any time), so after X.open the error handler drops
// them, as xmonad's does, and prints any other.

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/XKBlib.h>
#include <X11/Xproto.h>
#include <sys/wait.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <unistd.h>

static Display* x_dpy;
static Window   x_root;
static int      x_other_wm;

static Term x_words(Env e, const u32* p, u64 n) {
  Term xs = term_pak(CID(Nil), 0);
  for (u64 i = n; i > 0; i -= 1) {
    xs = io_node(e, CID(Con), (Term)p[i - 1], xs);
  }
  return xs;
}

#define x_ok(r) ((Term)(u32)(r))

// While X.open selects the root's events: a BadAccess there is another
// window manager.
static int x_start_error(Display* d, XErrorEvent* ev) {
  if (ev->error_code == BadAccess) {
    x_other_wm = 1;
  }
  return 0;
}

// xmonad's handler (X11's cbits): requests on a window that is gone, a
// focus or configure that does not match, a grab someone else holds.
static int x_error(Display* d, XErrorEvent* ev) {
  if (ev->error_code == BadWindow
      || (ev->request_code == X_SetInputFocus && ev->error_code == BadMatch)
      || (ev->request_code == X_PolyText8 && ev->error_code == BadDrawable)
      || (ev->request_code == X_PolyFillRectangle && ev->error_code == BadDrawable)
      || (ev->request_code == X_PolySegment && ev->error_code == BadDrawable)
      || (ev->request_code == X_ConfigureWindow && ev->error_code == BadMatch)
      || (ev->request_code == X_GrabButton && ev->error_code == BadAccess)
      || (ev->request_code == X_GrabKey && ev->error_code == BadAccess)
      || (ev->request_code == X_CopyArea && ev->error_code == BadDrawable)) {
    return 0;
  }
  fprintf(stderr, "xmonad-bend: X error: request code=%d, error code=%d\n",
    ev->request_code, ev->error_code);
  return 0;
}

// X.open(mask): the display named by $DISPLAY, its root selecting mask's
// events. [root, width, height], or [] when there is no display or another
// window manager holds the root.
#ifdef CID(open)
Term x_open_run(Env e, Term* f, IoWork* w) {
  x_dpy = XOpenDisplay(NULL);
  if (x_dpy == NULL) {
    return x_words(e, NULL, 0);
  }
  Screen* s = DefaultScreenOfDisplay(x_dpy);
  x_root = RootWindowOfScreen(s);
  XSetErrorHandler(x_start_error);
  XSelectInput(x_dpy, x_root, (long)(u32)f[0]);
  XSync(x_dpy, False);
  if (x_other_wm) {
    XCloseDisplay(x_dpy);
    x_dpy = NULL;
    return x_words(e, NULL, 0);
  }
  XSetErrorHandler(x_error);
  u32 r[3] = { (u32)x_root, (u32)WidthOfScreen(s), (u32)HeightOfScreen(s) };
  return x_words(e, r, 3);
}
static void __attribute__((constructor)) x_open_use(void) {
  io_eff(CID(open), x_open_run);
}
#endif

// X.modifiers: the modifier map, two words for each key in it: the
// modifier's index (0 Shift .. 7 Mod5) and the key's first keysym.
#ifdef CID(modifiers)
Term x_modifiers_run(Env e, Term* f, IoWork* w) {
  XModifierKeymap* m = XGetModifierMapping(x_dpy);
  u64 n = 0;
  u32* r = malloc(sizeof(u32) * 16 * (m->max_keypermod + 1));
  for (int i = 0; i < 8; i += 1) {
    for (int j = 0; j < m->max_keypermod; j += 1) {
      KeyCode kc = m->modifiermap[i * m->max_keypermod + j];
      if (kc != 0) {
        r[n++] = (u32)i;
        r[n++] = (u32)XkbKeycodeToKeysym(x_dpy, kc, 0, 0);
      }
    }
  }
  XFreeModifiermap(m);
  Term t = x_words(e, r, n);
  free(r);
  return t;
}
static void __attribute__((constructor)) x_modifiers_use(void) {
  io_eff(CID(modifiers), x_modifiers_run);
}
#endif

// X.atom(name): the atom of name, made if new
#ifdef CID(atom)
Term x_atom_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* name = io_cstr(e, f[0], &n);
  Atom a = XInternAtom(x_dpy, name, False);
  free(name);
  return x_ok(a);
}
static void __attribute__((constructor)) x_atom_use(void) {
  io_eff(CID(atom), x_atom_run);
}
#endif

// X.color(name): [the pixel of the named color] in the default colormap,
// or [] when X does not know the name
#ifdef CID(color)
Term x_color_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* name = io_cstr(e, f[0], &n);
  XColor got, exact;
  Colormap cm = DefaultColormap(x_dpy, DefaultScreen(x_dpy));
  Status ok = XAllocNamedColor(x_dpy, cm, name, &got, &exact);
  free(name);
  u32 r[1] = { (u32)got.pixel };
  return x_words(e, r, ok ? 1 : 0);
}
static void __attribute__((constructor)) x_color_use(void) {
  io_eff(CID(color), x_color_run);
}
#endif

// X.grab_key(mask, sym): grab mask with every key whose first keysym is sym,
// on the root; answers how many keys
#ifdef CID(grab_key)
Term x_grab_key_run(Env e, Term* f, IoWork* w) {
  int lo, hi;
  u32 n = 0;
  XDisplayKeycodes(x_dpy, &lo, &hi);
  for (int kc = lo; kc <= hi; kc += 1) {
    if (XkbKeycodeToKeysym(x_dpy, (KeyCode)kc, 0, 0) == (KeySym)(u32)f[1]) {
      XGrabKey(x_dpy, kc, (u32)f[0], x_root, True, GrabModeAsync, GrabModeAsync);
      n += 1;
    }
  }
  return x_ok(n);
}
static void __attribute__((constructor)) x_grab_key_use(void) {
  io_eff(CID(grab_key), x_grab_key_run);
}
#endif

#ifdef CID(ungrab_keys)
Term x_ungrab_keys_run(Env e, Term* f, IoWork* w) {
  XUngrabKey(x_dpy, AnyKey, AnyModifier, x_root);
  return x_ok(0);
}
static void __attribute__((constructor)) x_ungrab_keys_use(void) {
  io_eff(CID(ungrab_keys), x_ungrab_keys_run);
}
#endif

// X.grab_button(win, button, mask, owner, pointer_mode, keyboard_mode)
#ifdef CID(grab_button)
Term x_grab_button_run(Env e, Term* f, IoWork* w) {
  XGrabButton(x_dpy, (u32)f[1], (u32)f[2], (Window)(u32)f[0], (Bool)(u32)f[3],
    ButtonPressMask, (int)(u32)f[4], (int)(u32)f[5], None, None);
  return x_ok(0);
}
static void __attribute__((constructor)) x_grab_button_use(void) {
  io_eff(CID(grab_button), x_grab_button_run);
}
#endif

// X.ungrab_buttons(win): every button with every modifier
#ifdef CID(ungrab_buttons)
Term x_ungrab_buttons_run(Env e, Term* f, IoWork* w) {
  XUngrabButton(x_dpy, AnyButton, AnyModifier, (Window)(u32)f[0]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_ungrab_buttons_use(void) {
  io_eff(CID(ungrab_buttons), x_ungrab_buttons_run);
}
#endif

// X.next: the next event, waiting for one. Its words, after the type:
//   KeyPress         state, keysym (the key's first), time
//   ButtonPress      window, button, state, subwindow, x_root, y_root, time
//   ButtonRelease    the same
//   MotionNotify     x, y (relative to the event's window)
//   EnterNotify      window, mode, x_root, y_root, time
//   LeaveNotify      window, same_screen, time
//   DestroyNotify    window
//   UnmapNotify      window, send_event
//   MapRequest       window
//   ConfigureNotify  window, x, y, width, height
//   ConfigureRequest window, value_mask, x, y, width, height, border, above,
//                    detail
//   MappingNotify    request (the keyboard map is refreshed first)
//   PropertyNotify   window, atom
//   ClientMessage    window, message_type
// and nothing more for any other type.
#ifdef CID(next)
static Term x_event(Env e, XEvent* ev) {
  u32 r[10];
  u64 n = 0;
  r[n++] = (u32)ev->type;
  switch (ev->type) {
    case KeyPress:
      r[n++] = ev->xkey.state;
      r[n++] = (u32)XLookupKeysym(&ev->xkey, 0);
      r[n++] = (u32)ev->xkey.time;
      break;
    case ButtonPress:
    case ButtonRelease:
      r[n++] = (u32)ev->xbutton.window;
      r[n++] = ev->xbutton.button;
      r[n++] = ev->xbutton.state;
      r[n++] = (u32)ev->xbutton.subwindow;
      r[n++] = (u32)ev->xbutton.x_root;
      r[n++] = (u32)ev->xbutton.y_root;
      r[n++] = (u32)ev->xbutton.time;
      break;
    case MotionNotify:
      r[n++] = (u32)ev->xmotion.x;
      r[n++] = (u32)ev->xmotion.y;
      break;
    case EnterNotify:
      r[n++] = (u32)ev->xcrossing.window;
      r[n++] = (u32)ev->xcrossing.mode;
      r[n++] = (u32)ev->xcrossing.x_root;
      r[n++] = (u32)ev->xcrossing.y_root;
      r[n++] = (u32)ev->xcrossing.time;
      break;
    case LeaveNotify:
      r[n++] = (u32)ev->xcrossing.window;
      r[n++] = (u32)ev->xcrossing.same_screen;
      r[n++] = (u32)ev->xcrossing.time;
      break;
    case DestroyNotify:
      r[n++] = (u32)ev->xdestroywindow.window;
      break;
    case UnmapNotify:
      r[n++] = (u32)ev->xunmap.window;
      r[n++] = (u32)ev->xunmap.send_event;
      break;
    case MapRequest:
      r[n++] = (u32)ev->xmaprequest.window;
      break;
    case ConfigureNotify:
      r[n++] = (u32)ev->xconfigure.window;
      r[n++] = (u32)ev->xconfigure.x;
      r[n++] = (u32)ev->xconfigure.y;
      r[n++] = (u32)ev->xconfigure.width;
      r[n++] = (u32)ev->xconfigure.height;
      break;
    case ConfigureRequest:
      r[n++] = (u32)ev->xconfigurerequest.window;
      r[n++] = (u32)ev->xconfigurerequest.value_mask;
      r[n++] = (u32)ev->xconfigurerequest.x;
      r[n++] = (u32)ev->xconfigurerequest.y;
      r[n++] = (u32)ev->xconfigurerequest.width;
      r[n++] = (u32)ev->xconfigurerequest.height;
      r[n++] = (u32)ev->xconfigurerequest.border_width;
      r[n++] = (u32)ev->xconfigurerequest.above;
      r[n++] = (u32)ev->xconfigurerequest.detail;
      break;
    case MappingNotify:
      XRefreshKeyboardMapping(&ev->xmapping);
      r[n++] = (u32)ev->xmapping.request;
      break;
    case PropertyNotify:
      r[n++] = (u32)ev->xproperty.window;
      r[n++] = (u32)ev->xproperty.atom;
      break;
    case ClientMessage:
      r[n++] = (u32)ev->xclient.window;
      r[n++] = (u32)ev->xclient.message_type;
      break;
  }
  return x_words(e, r, n);
}

static Term x_next_more(Env e, IoWork* w) {
  if (XPending(x_dpy) == 0) {
    return io_wait_on(w, ConnectionNumber(x_dpy), POLLIN, 0, x_next_more);
  }
  XEvent ev;
  XNextEvent(x_dpy, &ev);
  return x_event(e, &ev);
}

Term x_next_run(Env e, Term* f, IoWork* w) {
  return x_next_more(e, w);
}
static void __attribute__((constructor)) x_next_use(void) {
  io_eff(CID(next), x_next_run);
}
#endif

// X.scan(wm_state): the root's children, four words each: the window, its
// override_redirect, its map_state and the first word of its WM_STATE
// property (0xFFFFFFFF when it has none); a child X cannot describe is left
// out
#ifdef CID(scan)
Term x_scan_run(Env e, Term* f, IoWork* w) {
  Window r, p, *ws = NULL;
  unsigned int n = 0;
  if (!XQueryTree(x_dpy, x_root, &r, &p, &ws, &n)) {
    return x_words(e, NULL, 0);
  }
  u32* out = malloc(sizeof(u32) * 4 * (n + 1));
  u64 k = 0;
  for (unsigned int i = 0; i < n; i += 1) {
    XWindowAttributes wa;
    if (!XGetWindowAttributes(x_dpy, ws[i], &wa)) {
      continue;
    }
    Atom t;
    int fmt;
    unsigned long items, after;
    unsigned char* data = NULL;
    u32 st = 0xFFFFFFFF;
    if (XGetWindowProperty(x_dpy, ws[i], (Atom)(u32)f[0], 0, 1, False,
          AnyPropertyType, &t, &fmt, &items, &after, &data) == Success
        && data != NULL && items > 0 && fmt == 32) {
      st = (u32)((long*)data)[0];
    }
    if (data != NULL) {
      XFree(data);
    }
    out[k++] = (u32)ws[i];
    out[k++] = (u32)wa.override_redirect;
    out[k++] = (u32)wa.map_state;
    out[k++] = st;
  }
  if (ws != NULL) {
    XFree(ws);
  }
  Term t = x_words(e, out, k);
  free(out);
  return t;
}
static void __attribute__((constructor)) x_scan_use(void) {
  io_eff(CID(scan), x_scan_run);
}
#endif

// X.attrs(win): [x, y, width, height, border_width, override_redirect,
// map_state], or [] when the window is gone
#ifdef CID(attrs)
Term x_attrs_run(Env e, Term* f, IoWork* w) {
  XWindowAttributes wa;
  if (!XGetWindowAttributes(x_dpy, (Window)(u32)f[0], &wa)) {
    return x_words(e, NULL, 0);
  }
  u32 r[7] = { (u32)wa.x, (u32)wa.y, (u32)wa.width, (u32)wa.height,
    (u32)wa.border_width, (u32)wa.override_redirect, (u32)wa.map_state };
  return x_words(e, r, 7);
}
static void __attribute__((constructor)) x_attrs_use(void) {
  io_eff(CID(attrs), x_attrs_run);
}
#endif

// X.normal_hints(win): WM_NORMAL_HINTS as [flags, min w, min h, max w,
// max h, inc w, inc h, min aspect x, y, max aspect x, y, base w, base h];
// flags 0 (and zeros) when the window has none, as Xlib leaves them
#ifdef CID(normal_hints)
Term x_normal_hints_run(Env e, Term* f, IoWork* w) {
  XSizeHints sh;
  long got = 0;
  memset(&sh, 0, sizeof sh);
  if (!XGetWMNormalHints(x_dpy, (Window)(u32)f[0], &sh, &got)) {
    memset(&sh, 0, sizeof sh);
  }
  u32 r[13] = { (u32)sh.flags, (u32)sh.min_width, (u32)sh.min_height,
    (u32)sh.max_width, (u32)sh.max_height, (u32)sh.width_inc,
    (u32)sh.height_inc, (u32)sh.min_aspect.x, (u32)sh.min_aspect.y,
    (u32)sh.max_aspect.x, (u32)sh.max_aspect.y, (u32)sh.base_width,
    (u32)sh.base_height };
  return x_words(e, r, 13);
}
static void __attribute__((constructor)) x_normal_hints_use(void) {
  io_eff(CID(normal_hints), x_normal_hints_run);
}
#endif

// X.transient_for(win): [the window it is transient for], or []
#ifdef CID(transient_for)
Term x_transient_for_run(Env e, Term* f, IoWork* w) {
  Window t = None;
  if (!XGetTransientForHint(x_dpy, (Window)(u32)f[0], &t)) {
    return x_words(e, NULL, 0);
  }
  u32 r[1] = { (u32)t };
  return x_words(e, r, 1);
}
static void __attribute__((constructor)) x_transient_for_use(void) {
  io_eff(CID(transient_for), x_transient_for_run);
}
#endif

// X.class_hint(win): WM_CLASS's class (its second string), one word per
// byte; [] when the window has no WM_CLASS (getClassHint: "")
#ifdef CID(class_hint)
Term x_class_hint_run(Env e, Term* f, IoWork* w) {
  XClassHint ch = { NULL, NULL };
  if (!XGetClassHint(x_dpy, (Window)(u32)f[0], &ch)) {
    return x_words(e, NULL, 0);
  }
  u64 n = ch.res_class != NULL ? strlen(ch.res_class) : 0;
  u32* r = malloc(sizeof(u32) * (n + 1));
  for (u64 i = 0; i < n; i += 1) {
    r[i] = (u32)(unsigned char)ch.res_class[i];
  }
  if (ch.res_name != NULL) {
    XFree(ch.res_name);
  }
  if (ch.res_class != NULL) {
    XFree(ch.res_class);
  }
  Term t = x_words(e, r, n);
  free(r);
  return t;
}
static void __attribute__((constructor)) x_class_hint_use(void) {
  io_eff(CID(class_hint), x_class_hint_run);
}
#endif

// X.wm_hints(win): [flags, input] of WM_HINTS, [0, 0] when it has none
#ifdef CID(wm_hints)
Term x_wm_hints_run(Env e, Term* f, IoWork* w) {
  XWMHints* h = XGetWMHints(x_dpy, (Window)(u32)f[0]);
  u32 r[2] = { 0, 0 };
  if (h != NULL) {
    r[0] = (u32)h->flags;
    r[1] = (u32)h->input;
    XFree(h);
  }
  return x_words(e, r, 2);
}
static void __attribute__((constructor)) x_wm_hints_use(void) {
  io_eff(CID(wm_hints), x_wm_hints_run);
}
#endif

// X.protocols(win): the atoms of its WM_PROTOCOLS
#ifdef CID(protocols)
Term x_protocols_run(Env e, Term* f, IoWork* w) {
  Atom* ps = NULL;
  int n = 0;
  if (!XGetWMProtocols(x_dpy, (Window)(u32)f[0], &ps, &n)) {
    return x_words(e, NULL, 0);
  }
  u32* r = malloc(sizeof(u32) * (n + 1));
  for (int i = 0; i < n; i += 1) {
    r[i] = (u32)ps[i];
  }
  XFree(ps);
  Term t = x_words(e, r, n);
  free(r);
  return t;
}
static void __attribute__((constructor)) x_protocols_use(void) {
  io_eff(CID(protocols), x_protocols_run);
}
#endif

// X.pointer: [root x, root y, the root's child under the pointer (0 if
// none)]
#ifdef CID(pointer)
Term x_pointer_run(Env e, Term* f, IoWork* w) {
  Window r, c;
  int rx, ry, wx, wy;
  unsigned int m;
  if (!XQueryPointer(x_dpy, x_root, &r, &c, &rx, &ry, &wx, &wy, &m)) {
    return x_words(e, NULL, 0);
  }
  u32 o[3] = { (u32)rx, (u32)ry, (u32)c };
  return x_words(e, o, 3);
}
static void __attribute__((constructor)) x_pointer_use(void) {
  io_eff(CID(pointer), x_pointer_run);
}
#endif

// X.xinerama: Xinerama's screens, four words each (x, y, width, height),
// or [] when it answers none (XineramaQueryScreens gives NULL: no
// extension, or not active). libXinerama is opened at the first use (at
// X_XINERAMA, a path the build may give, else by its soname), so a build
// needs only libX11; without the library there are no Xinerama screens,
// as without the extension.
#ifdef CID(xinerama)
#ifndef X_XINERAMA
#define X_XINERAMA "libXinerama.so.1"
#endif
typedef struct {
  int   screen_number;
  short x_org, y_org, width, height;
} x_XineramaScreenInfo;
Term x_xinerama_run(Env e, Term* f, IoWork* w) {
  static int tried;
  static x_XineramaScreenInfo* (*query)(Display*, int*);
  if (!tried) {
    tried = 1;
    void* lib = dlopen(X_XINERAMA, RTLD_NOW | RTLD_LOCAL);
    if (lib != NULL) {
      query = (x_XineramaScreenInfo* (*)(Display*, int*))dlsym(lib,
        "XineramaQueryScreens");
    }
  }
  int n = 0;
  x_XineramaScreenInfo* s = query != NULL ? query(x_dpy, &n) : NULL;
  if (s == NULL) {
    return x_words(e, NULL, 0);
  }
  u32* r = malloc(sizeof(u32) * 4 * (u64)(n > 0 ? n : 1));
  for (int i = 0; i < n; i += 1) {
    r[4 * i + 0] = (u32)(int)s[i].x_org;
    r[4 * i + 1] = (u32)(int)s[i].y_org;
    r[4 * i + 2] = (u32)(int)s[i].width;
    r[4 * i + 3] = (u32)(int)s[i].height;
  }
  XFree(s);
  Term t = x_words(e, r, 4 * (u64)n);
  free(r);
  return t;
}
static void __attribute__((constructor)) x_xinerama_use(void) {
  io_eff(CID(xinerama), x_xinerama_run);
}
#endif

// Requests: each answers 0.

#ifdef CID(select_input)
Term x_select_input_run(Env e, Term* f, IoWork* w) {
  XSelectInput(x_dpy, (Window)(u32)f[0], (long)(u32)f[1]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_select_input_use(void) {
  io_eff(CID(select_input), x_select_input_run);
}
#endif

#ifdef CID(map)
Term x_map_run(Env e, Term* f, IoWork* w) {
  XMapWindow(x_dpy, (Window)(u32)f[0]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_map_use(void) {
  io_eff(CID(map), x_map_run);
}
#endif

#ifdef CID(unmap)
Term x_unmap_run(Env e, Term* f, IoWork* w) {
  XUnmapWindow(x_dpy, (Window)(u32)f[0]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_unmap_use(void) {
  io_eff(CID(unmap), x_unmap_run);
}
#endif

#ifdef CID(raise)
Term x_raise_run(Env e, Term* f, IoWork* w) {
  XRaiseWindow(x_dpy, (Window)(u32)f[0]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_raise_use(void) {
  io_eff(CID(raise), x_raise_run);
}
#endif

// X.stack_below(win, sibling): win just below sibling
#ifdef CID(stack_below)
Term x_stack_below_run(Env e, Term* f, IoWork* w) {
  XWindowChanges wc;
  wc.sibling    = (Window)(u32)f[1];
  wc.stack_mode = Below;
  XConfigureWindow(x_dpy, (Window)(u32)f[0], CWSibling | CWStackMode, &wc);
  return x_ok(0);
}
static void __attribute__((constructor)) x_stack_below_use(void) {
  io_eff(CID(stack_below), x_stack_below_run);
}
#endif

// X.move_resize(win, x, y, width, height)
#ifdef CID(move_resize)
Term x_move_resize_run(Env e, Term* f, IoWork* w) {
  XMoveResizeWindow(x_dpy, (Window)(u32)f[0], (int)(u32)f[1], (int)(u32)f[2],
    (u32)f[3], (u32)f[4]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_move_resize_use(void) {
  io_eff(CID(move_resize), x_move_resize_run);
}
#endif

// X.move(win, x, y), X.resize(win, width, height)
#ifdef CID(move)
Term x_move_run(Env e, Term* f, IoWork* w) {
  XMoveWindow(x_dpy, (Window)(u32)f[0], (int)(u32)f[1], (int)(u32)f[2]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_move_use(void) {
  io_eff(CID(move), x_move_run);
}
#endif

#ifdef CID(resize)
Term x_resize_run(Env e, Term* f, IoWork* w) {
  XResizeWindow(x_dpy, (Window)(u32)f[0], (u32)f[1], (u32)f[2]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_resize_use(void) {
  io_eff(CID(resize), x_resize_run);
}
#endif

// X.warp(win, x, y): the pointer to x, y in win (warpPointer d none w 0 0 0
// 0 x y)
#ifdef CID(warp)
Term x_warp_run(Env e, Term* f, IoWork* w) {
  XWarpPointer(x_dpy, None, (Window)(u32)f[0], 0, 0, 0, 0, (int)(u32)f[1],
    (int)(u32)f[2]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_warp_use(void) {
  io_eff(CID(warp), x_warp_run);
}
#endif

// X.grab_pointer(mask, glyph): mouseDragCursor's grab: the pointer to the
// root, not owner_events, for mask's events, both modes async, no
// confine, the cursor font's glyph as the cursor
#ifdef CID(grab_pointer)
Term x_grab_pointer_run(Env e, Term* f, IoWork* w) {
  Cursor c = XCreateFontCursor(x_dpy, (u32)f[1]);
  XGrabPointer(x_dpy, x_root, False, (u32)f[0], GrabModeAsync, GrabModeAsync,
    None, c, CurrentTime);
  return x_ok(0);
}
static void __attribute__((constructor)) x_grab_pointer_use(void) {
  io_eff(CID(grab_pointer), x_grab_pointer_run);
}
#endif

#ifdef CID(ungrab_pointer)
Term x_ungrab_pointer_run(Env e, Term* f, IoWork* w) {
  XUngrabPointer(x_dpy, CurrentTime);
  return x_ok(0);
}
static void __attribute__((constructor)) x_ungrab_pointer_use(void) {
  io_eff(CID(ungrab_pointer), x_ungrab_pointer_run);
}
#endif

#ifdef CID(border_width)
Term x_border_width_run(Env e, Term* f, IoWork* w) {
  XSetWindowBorderWidth(x_dpy, (Window)(u32)f[0], (u32)f[1]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_border_width_use(void) {
  io_eff(CID(border_width), x_border_width_run);
}
#endif

#ifdef CID(border_color)
Term x_border_color_run(Env e, Term* f, IoWork* w) {
  XSetWindowBorder(x_dpy, (Window)(u32)f[0], (unsigned long)(u32)f[1]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_border_color_use(void) {
  io_eff(CID(border_color), x_border_color_run);
}
#endif

// X.set_prop32(win, property, type, a, b): property := [a, b], 32-bit
// (WM_STATE's shape)
#ifdef CID(set_prop32)
Term x_set_prop32_run(Env e, Term* f, IoWork* w) {
  long v[2] = { (long)(u32)f[3], (long)(u32)f[4] };
  XChangeProperty(x_dpy, (Window)(u32)f[0], (Atom)(u32)f[1], (Atom)(u32)f[2],
    32, PropModeReplace, (unsigned char*)v, 2);
  return x_ok(0);
}
static void __attribute__((constructor)) x_set_prop32_use(void) {
  io_eff(CID(set_prop32), x_set_prop32_run);
}
#endif

// X.set_focus(win): the input focus, reverting to the pointer's root
#ifdef CID(set_focus)
Term x_set_focus_run(Env e, Term* f, IoWork* w) {
  XSetInputFocus(x_dpy, (Window)(u32)f[0], RevertToPointerRoot, CurrentTime);
  return x_ok(0);
}
static void __attribute__((constructor)) x_set_focus_use(void) {
  io_eff(CID(set_focus), x_set_focus_run);
}
#endif

// X.send_message(win, type, a, b): a ClientMessage of format 32 with data
// [a, b, 0, 0, 0] (WM_PROTOCOLS' shape: the protocol and a time)
#ifdef CID(send_message)
Term x_send_message_run(Env e, Term* f, IoWork* w) {
  XEvent ev;
  memset(&ev, 0, sizeof ev);
  ev.xclient.type         = ClientMessage;
  ev.xclient.window       = (Window)(u32)f[0];
  ev.xclient.message_type = (Atom)(u32)f[1];
  ev.xclient.format       = 32;
  ev.xclient.data.l[0]    = (long)(u32)f[2];
  ev.xclient.data.l[1]    = (long)(u32)f[3];
  XSendEvent(x_dpy, (Window)(u32)f[0], False, NoEventMask, &ev);
  return x_ok(0);
}
static void __attribute__((constructor)) x_send_message_use(void) {
  io_eff(CID(send_message), x_send_message_run);
}
#endif

#ifdef CID(kill_client)
Term x_kill_client_run(Env e, Term* f, IoWork* w) {
  XKillClient(x_dpy, (XID)(u32)f[0]);
  return x_ok(0);
}
static void __attribute__((constructor)) x_kill_client_use(void) {
  io_eff(CID(kill_client), x_kill_client_run);
}
#endif

// X.configure(win, mask, x, y, width, height, border, sibling, stack_mode):
// the changes mask names
#ifdef CID(configure)
Term x_configure_run(Env e, Term* f, IoWork* w) {
  XWindowChanges wc;
  wc.x            = (int)(u32)f[2];
  wc.y            = (int)(u32)f[3];
  wc.width        = (int)(u32)f[4];
  wc.height       = (int)(u32)f[5];
  wc.border_width = (int)(u32)f[6];
  wc.sibling      = (Window)(u32)f[7];
  wc.stack_mode   = (int)(u32)f[8];
  XConfigureWindow(x_dpy, (Window)(u32)f[0], (u32)f[1], &wc);
  return x_ok(0);
}
static void __attribute__((constructor)) x_configure_use(void) {
  io_eff(CID(configure), x_configure_run);
}
#endif

// X.configure_notify(win, x, y, width, height, border, override): a
// synthetic ConfigureNotify telling win where it is
#ifdef CID(configure_notify)
Term x_configure_notify_run(Env e, Term* f, IoWork* w) {
  XEvent ev;
  memset(&ev, 0, sizeof ev);
  ev.xconfigure.type              = ConfigureNotify;
  ev.xconfigure.event             = (Window)(u32)f[0];
  ev.xconfigure.window            = (Window)(u32)f[0];
  ev.xconfigure.x                 = (int)(u32)f[1];
  ev.xconfigure.y                 = (int)(u32)f[2];
  ev.xconfigure.width             = (int)(u32)f[3];
  ev.xconfigure.height            = (int)(u32)f[4];
  ev.xconfigure.border_width      = (int)(u32)f[5];
  ev.xconfigure.above             = None;
  ev.xconfigure.override_redirect = (Bool)(u32)f[6];
  XSendEvent(x_dpy, (Window)(u32)f[0], False, 0, &ev);
  return x_ok(0);
}
static void __attribute__((constructor)) x_configure_notify_use(void) {
  io_eff(CID(configure_notify), x_configure_notify_run);
}
#endif

// X.spawn(command): /bin/sh -c command, in a session of its own, not
// waited for. It runs as a grandchild (the child exits at once and is
// reaped here), so no zombie is left and no signal handler is changed.
#ifdef CID(spawn)
Term x_spawn_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* cmd = io_cstr(e, f[0], &n);
  pid_t p = fork();
  if (p == 0) {
    if (x_dpy != NULL) {
      close(ConnectionNumber(x_dpy));
    }
    setsid();
    if (fork() == 0) {
      execl("/bin/sh", "/bin/sh", "-c", cmd, (char*)NULL);
      _exit(127);
    }
    _exit(0);
  }
  if (p > 0) {
    waitpid(p, NULL, 0);
  }
  free(cmd);
  return x_ok(p > 0 ? 0 : 1);
}
static void __attribute__((constructor)) x_spawn_use(void) {
  io_eff(CID(spawn), x_spawn_run);
}
#endif

#ifdef CID(sync)
Term x_sync_run(Env e, Term* f, IoWork* w) {
  XSync(x_dpy, False);
  return x_ok(0);
}
static void __attribute__((constructor)) x_sync_use(void) {
  io_eff(CID(sync), x_sync_run);
}
#endif

// X.drop_events(mask): sync, then drop every queued event in mask
// (xmonad's clearEvents)
#ifdef CID(drop_events)
Term x_drop_events_run(Env e, Term* f, IoWork* w) {
  XEvent ev;
  XSync(x_dpy, False);
  while (XCheckMaskEvent(x_dpy, (long)(u32)f[0], &ev)) {
  }
  return x_ok(0);
}
static void __attribute__((constructor)) x_drop_events_use(void) {
  io_eff(CID(drop_events), x_drop_events_run);
}
#endif

// Not X: the system calls xmonad's restart and its state file need, besides
// Bend's own.

// X.mkdir(path): mkdir with mode 0777 (less the umask); 0 or errno
#ifdef CID(mkdir)
Term x_mkdir_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* path = io_cstr(e, f[0], &n);
  int r = mkdir(path, 0777) == 0 ? 0 : errno;
  free(path);
  return x_ok(r);
}
static void __attribute__((constructor)) x_mkdir_use(void) {
  io_eff(CID(mkdir), x_mkdir_run);
}
#endif

// X.unlink(path): 0 or errno
#ifdef CID(unlink)
Term x_unlink_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* path = io_cstr(e, f[0], &n);
  int r = unlink(path) == 0 ? 0 : errno;
  free(path);
  return x_ok(r);
}
static void __attribute__((constructor)) x_unlink_use(void) {
  io_eff(CID(unlink), x_unlink_run);
}
#endif

// X.exec(program): xmonad's restart (executeFile prog True [] Nothing):
// the display flushed (its connection closes on exec), the signal mask
// cleared (the runtime's threads may block some, and exec keeps the mask),
// then program in this process's place, found by PATH, with no arguments.
// Answers only if exec fails: errno, the mask as it was.
#ifdef CID(exec)
Term x_exec_run(Env e, Term* f, IoWork* w) {
  u64 n = 0;
  char* prog = io_cstr(e, f[0], &n);
  sigset_t none, old;
  if (x_dpy != NULL) {
    XFlush(x_dpy);
    fcntl(ConnectionNumber(x_dpy), F_SETFD, FD_CLOEXEC);
  }
  sigemptyset(&none);
  pthread_sigmask(SIG_SETMASK, &none, &old);
  execlp(prog, prog, (char*)NULL);
  int r = errno;
  pthread_sigmask(SIG_SETMASK, &old, NULL);
  free(prog);
  return x_ok(r);
}
static void __attribute__((constructor)) x_exec_use(void) {
  io_eff(CID(exec), x_exec_run);
}
#endif
