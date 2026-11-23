# xmonad's state file in Bend: the windowset as Haskell's show writes it,
# and read back.
#
# What it means. A restart (XMONAD_RESTART, which `xmonad --restart` sends)
# writes the windowset to the state file, xmonad.state in xmonad's data
# directory (XMonad.Operations.writeStateToFile: show (StateFile (W.mapLayout
# show ws) ext)), and the window manager that starts next reads it back
# (readStateFile: the layouts read by the layout's Read, the default layout
# for one that does not read, then W.ensureTags), so the windows stay on
# their workspaces and in their places. The text here is xmonad's own,
# character for character, so xmonad and xmonad-bend each read the other's
# file.
#
# Reading. Bend matches only parameters and their fields, never a computed
# value, and a function cannot be used twice, so: the text is first cut
# into classed characters (CC) and then tokens, identifiers already turned
# into codes (kw), so every choice is a match on a constructor or a
# literal; each parser is written in continuation style, handing what it
# read and the tokens left to its continuation (or answering None); a list
# keeps what it has read in an accumulator, in one def with a mode. Every
# recursion counts down a fuel (the length of the text or of the tokens).

import Base
import ./StackSet.bend as W
import ./Layout.bend as L
import ./Num.bend as N
import ./Core.bend as C

# Showing (Haskell's derived Show) -------------------------------------------------

def hs.paren(on: Bool, s: String) -> String:
  match on:
    case True{}:
      "(" ++ s ++ ")"
    case False{}:
      s

def hs.u32(w: U32) -> String:
  Nat.show(U32.to_nat(w))

# a Position (an Int32 in a U32), at precedence 0
def hs.pos(+w: U32) -> String:
  Bool.pick(String, U32.is_lt(w, 2147483648), Nat.show(U32.to_nat(w)), "-" ++ Nat.show(U32.to_nat(U32.add(U32.not(w), 1))))

# an Integer at precedence p: a negative one in parentheses above 6
def hs.int(+p: Nat, a: N.Int) -> String:
  match a:
    case N.Int.Pos{n}:
      Nat.show(n)
    case N.Int.Neg{n}:
      hs.paren(Nat.is_gt(p, 6n), "-" ++ Nat.show(1n+n))

def hs.rat.go(+p: Nat, r: N.Rat) -> String:
  match r:
    case N.Rat{n, d}:
      hs.paren(Nat.is_gt(p, 7n), hs.int(8n, n) ++ " % " ++ Nat.show(1n+d))

# a Rational at precedence p (reduced, as Haskell keeps it)
def hs.rat(+p: Nat, r: N.Rat) -> String:
  hs.rat.go(p, N.Rat.norm(r))

def hs.side(s: L.Side) -> String:
  match s:
    case L.CL{}:
      "CL"
    case L.CR{}:
      "CR"

# a layout at precedence p: Choose, Mirror, Full, Tall's record
def hs.layout(l: L.Layout, +p: Nat) -> String:
  match l:
    case L.Full{}:
      "Full"
    case L.Tall{nm, d, f}:
      hs.paren(Nat.is_gt(p, 10n), "Tall {tallNMaster = " ++ hs.int(0n, nm) ++ ", tallRatioIncrement = " ++ hs.rat(0n, d) ++ ", tallRatio = " ++ hs.rat(0n, f) ++ "}")
    case L.Mirror{x}:
      hs.paren(Nat.is_gt(p, 10n), "Mirror " ++ hs.layout(x, 11n))
    case L.Choose{s, a, b}:
      hs.paren(Nat.is_gt(p, 10n), "Choose " ++ hs.side(s) ++ " " ++ hs.layout(a, 11n) ++ " " ++ hs.layout(b, 11n))

# ASCII's controls by name, 0 to 31, and SP (GHC's asciiTab)
def esc.names() -> List<&2, String>:
  ["NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT", "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US", "SP"]

# the controls 7 to 13 by letter
def esc.letters() -> List<&2, String>:
  ["a", "b", "t", "n", "v", "f", "r"]

def hs.nth(n: Nat, xs: List<&2, String>) -> String:
  match n xs:
    case 0n x <> _:
      x
    case 1n+m _ <> rest:
      hs.nth(m, rest)
    case _ _:
      ""

def hs.protect(on: Bool) -> String:
  match on:
    case True{}:
      "\\&"
    case False{}:
      ""

# whether a text starts with a character from lo to hi
def hs.next.in(t: String, +lo: U32, +hi: U32) -> Bool:
  match t:
    case SCon{c, _}:
      +u = Char.to_u32(c)
      Bool.and(U32.is_ge(u, lo), U32.is_le(u, hi))
    case SNil{}:
      False{}

# a character inside a shown string, as GHC's showLitString writes it: \"
# and \\; the controls 7 to 13 by letter, the others by ASCII's names (\SO
# with \& after it before an H), DEL; any other non-ASCII character as \ and
# its decimal code (with \& after it before a digit); the rest as itself.
# t: what follows the character
def hs.char.code(+u: U32, +t: String) -> String:
  W.Bool.if(String, U32.is_eq(u, 34), _ => "\\\"", _ => W.Bool.if(String, U32.is_eq(u, 92), _ => "\\\\", _ => W.Bool.if(String, U32.is_eq(u, 127), _ => "\\DEL", _ => W.Bool.if(String, U32.is_gt(u, 127), _ => "\\" ++ Nat.show(U32.to_nat(u)) ++ hs.protect(hs.next.in(t, 48, 57)), _ => W.Bool.if(String, U32.is_ge(u, 32), _ => SCon{Char.from_u32(u), SNil{}}, _ => W.Bool.if(String, Bool.and(U32.is_ge(u, 7), U32.is_le(u, 13)), _ => "\\" ++ hs.nth(Nat.sub(U32.to_nat(u), 7n), esc.letters()), _ => W.Bool.if(String, U32.is_eq(u, 14), _ => "\\SO" ++ hs.protect(hs.next.in(t, 72, 72)), _ => "\\" ++ hs.nth(U32.to_nat(u), esc.names()))))))))

def hs.char(c: Char, +t: String) -> String:
  hs.char.code(Char.to_u32(c), t)


def hs.str.go(s: String) -> String:
  match s:
    case SNil{}:
      "\""
    case SCon{c, +t}:
      hs.char(c, t) ++ hs.str.go(t)

def hs.str(s: String) -> String:
  "\"" ++ hs.str.go(s)

def hs.join(xs: List<&2, String>) -> String:
  match xs:
    case Nil{}:
      ""
    case x <> Nil{}:
      x
    case x <> rest:
      x ++ "," ++ hs.join(rest)

def hs.list(xs: List<&2, String>) -> String:
  "[" ++ hs.join(xs) ++ "]"

def hs.wins.go(ws: List<&2, U32>) -> List<&2, String>:
  match ws:
    case Nil{}:
      Nil{}
    case w <> rest:
      hs.u32(w) <> hs.wins.go(rest)

def hs.wins(ws: List<&2, U32>) -> String:
  hs.list(hs.wins.go(ws))

def hs.stack(m: Maybe<&2, W.Stack<U32>>) -> String:
  match m:
    case None{}:
      "Nothing"
    case Some{W.Stack{f, u, d}}:
      "Just (Stack {focus = " ++ hs.u32(f) ++ ", up = " ++ hs.wins(u) ++ ", down = " ++ hs.wins(d) ++ "})"

# a workspace, its layout shown (W.mapLayout show) and then shown as a String
def hs.workspace(w: C.WindowSpace()) -> String:
  match w:
    case W.Workspace{t, l, st}:
      "Workspace {tag = " ++ hs.str(t) ++ ", layout = " ++ hs.str(hs.layout(l, 0n)) ++ ", stack = " ++ hs.stack(st) ++ "}"

def hs.rect(r: L.Rectangle) -> String:
  match r:
    case L.Rectangle{x, y, w, h}:
      "Rectangle {rect_x = " ++ hs.pos(x) ++ ", rect_y = " ++ hs.pos(y) ++ ", rect_width = " ++ hs.u32(w) ++ ", rect_height = " ++ hs.u32(h) ++ "}"

def hs.screen(s: C.WScreen()) -> String:
  match s:
    case W.Screen{w, i, r}:
      "Screen {workspace = " ++ hs.workspace(w) ++ ", screen = S " ++ Nat.show(i) ++ ", screenDetail = SD {screenRect = " ++ hs.rect(r) ++ "}}"

def hs.screens(xs: List<&2, C.WScreen()>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      hs.screen(x) <> hs.screens(rest)

def hs.workspaces(xs: List<&2, C.WindowSpace()>) -> List<&2, String>:
  match xs:
    case Nil{}:
      Nil{}
    case x <> rest:
      hs.workspace(x) <> hs.workspaces(rest)

def hs.rr(r: W.RationalRect) -> String:
  match r:
    case W.RationalRect{x, y, w, h}:
      "RationalRect " ++ hs.rat(11n, x) ++ " " ++ hs.rat(11n, y) ++ " " ++ hs.rat(11n, w) ++ " " ++ hs.rat(11n, h)

def hs.floats(fs: List<&2, W.Float<U32>>) -> List<&2, String>:
  match fs:
    case Nil{}:
      Nil{}
    case W.Float{w, r} <> rest:
      ("(" ++ hs.u32(w) ++ "," ++ hs.rr(r) ++ ")") <> hs.floats(rest)

# the windowset as W.mapLayout show of it shows (floating is a Data.Map, in
# its key order, as the list keeps it)
def hs.windowset(s: C.WindowSet()) -> String:
  match s:
    case W.StackSet{c, v, h, f}:
      "StackSet {current = " ++ hs.screen(c) ++ ", visible = " ++ hs.list(hs.screens(v)) ++ ", hidden = " ++ hs.list(hs.workspaces(h)) ++ ", floating = fromList " ++ hs.list(hs.floats(f)) ++ "}"

# the state file's text: show (StateFile ...), no extensible state, no
# newline at the end
def show(s: C.WindowSet()) -> String:
  "StateFile {sfWins = " ++ hs.windowset(s) ++ ", sfExt = []}"

# Characters, classed ----------------------------------------------------------------

type CC is Data:
  CDigit{d: Nat}
  # a letter or _
  CAlpha{c: Char}
  # white space as Haskell's isSpace says, Latin-1's (tab to carriage
  # return, space, no-break space); the other Unicode spaces are symbols
  CSpace{c: Char}
  CQuote{}
  CBack{}
  # anything else, by its code
  CSym{n: Nat}

def cc.of(+c: Char) -> CC:
  +u = Char.to_u32(c)
  W.Bool.if(CC, Bool.and(U32.is_ge(u, 48), U32.is_le(u, 57)), _ => CDigit{U32.to_nat(U32.sub(u, 48))}, _ => W.Bool.if(CC, Bool.or(Bool.or(Bool.and(U32.is_ge(u, 65), U32.is_le(u, 90)), Bool.and(U32.is_ge(u, 97), U32.is_le(u, 122))), U32.is_eq(u, 95)), _ => CAlpha{c}, _ => W.Bool.if(CC, Bool.or(Bool.or(U32.is_eq(u, 32), U32.is_eq(u, 160)), Bool.and(U32.is_ge(u, 9), U32.is_le(u, 13))), _ => CSpace{c}, _ => W.Bool.if(CC, U32.is_eq(u, 34), _ => CQuote{}, _ => W.Bool.if(CC, U32.is_eq(u, 92), _ => CBack{}, _ => CSym{U32.to_nat(u)})))))

def cc.all(s: String) -> List<&2, CC>:
  match s:
    case SNil{}:
      Nil{}
    case SCon{c, t}:
      cc.of(c) <> cc.all(t)

def CCs() -> Data:
  List<&2, CC>

def cc.digit(d: Nat) -> Char:
  Char.from_u32(U32.add(48, U32.from_nat(d)))

# Tokens -------------------------------------------------------------------------

type Tok is Data:
  # an identifier, by its code (kw)
  TKw{k: Nat}
  TNum{n: Nat}
  TStr{s: String}
  TSym{c: Nat}

def Toks() -> Data:
  List<&2, Tok>

# the identifiers a state file has; an identifier's code is its place here
# from 1 (0: any other)
def kw.names() -> List<&2, String>:
  ["StateFile", "sfWins", "StackSet", "current", "visible", "hidden", "floating", "fromList", "sfExt", "Screen", "workspace", "screen", "S", "screenDetail", "SD", "screenRect", "Rectangle", "rect_x", "rect_y", "rect_width", "rect_height", "Workspace", "tag", "layout", "stack", "Nothing", "Just", "Stack", "focus", "up", "down", "RationalRect", "Choose", "CL", "CR", "Mirror", "Full", "Tall", "tallNMaster", "tallRatioIncrement", "tallRatio"]

def kw.find(+s: String, ns: List<&2, String>, +i: Nat) -> Nat:
  match ns:
    case Nil{}:
      0n
    case n <> rest:
      W.Bool.if(Nat, String.eq(s, n), _ => i, _ => kw.find(s, rest, 1n+i))

def kw(+s: String) -> Nat:
  kw.find(s, kw.names(), 1n)

# the digits after the first (n so far)
def lex.num(fuel: Nat, +n: Nat, cs: CCs(), k: Nat -> CCs() -> Toks()) -> Toks():
  match fuel:
    case 0n:
      k(n, cs)
    case 1n+f:
      match cs:
        case CDigit{d} <> rest:
          lex.num(f, Nat.add(Nat.mul(n, 10n), d), rest, k)
        case other:
          k(n, other)

# an identifier's characters after its first (letters, digits, _ and ')
def lex.id(fuel: Nat, cs: CCs(), k: String -> CCs() -> Toks()) -> Toks():
  match fuel:
    case 0n:
      k(SNil{}, cs)
    case 1n+f:
      match cs:
        case CAlpha{c} <> rest:
          lex.id(f, rest, a => r => k(SCon{c, a}, r))
        case CDigit{d} <> rest:
          lex.id(f, rest, a => r => k(SCon{cc.digit(d), a}, r))
        case CSym{39n} <> rest:
          lex.id(f, rest, a => r => k(SCon{Char.from_u32(39), a}, r))
        case other:
          k(SNil{}, other)

# up to n characters from the front, letters and digits only
def lex.word(cs: CCs(), n: Nat) -> String:
  match cs n:
    case CAlpha{c} <> rest 1n+m:
      SCon{c, lex.word(rest, m)}
    case CDigit{d} <> rest 1n+m:
      SCon{cc.digit(d), lex.word(rest, m)}
    case _ _:
      SNil{}

# an escape's name: its character's code and one, or 0 if it is not one
def esc.code(+s: String) -> Nat:
  +n = kw.find(s, esc.names(), 1n)
  +l = kw.find(s, esc.letters(), 1n)
  Bool.pick(Nat, Nat.is_gt(n, 0n), n, Bool.pick(Nat, Nat.is_gt(l, 0n), Nat.add(l, 7n), Bool.pick(Nat, String.eq(s, "DEL"), 128n, 0n)))

# the longest escape's name after a backslash (Text.Read.Lex's: SOH before
# SO), its first letter a taken already and cs what follows a: its text
def esc.take(+a: Char, +cs: CCs()) -> String:
  +p3 : String = SCon{a, lex.word(cs, 2n)}
  +p2 : String = SCon{a, lex.word(cs, 1n)}
  Bool.pick(String, Nat.is_gt(esc.code(p3), 0n), p3, Bool.pick(String, Nat.is_gt(esc.code(p2), 0n), p2, SCon{a, SNil{}}))

def lex.esc.code(n: Nat) -> Char:
  Char.from_u32(U32.from_nat(n))

# a string's characters after its opening quote, to its closing one;
# escapes: \" \\ \', a b t n v f r, ASCII's names (and SP, DEL), \& (nothing)
# and \ with a decimal code. Not read (Haskell reads them, show never
# writes them): \^X, \o and \x codes, gaps.
def lex.str(fuel: Nat, cs: CCs(), k: String -> CCs() -> Toks()) -> Toks():
  match fuel cs:
    case 0n _:
      Nil{}
    case 1n+f CQuote{} <> rest:
      k(SNil{}, rest)
    case 1n+f CBack{} <> CQuote{} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{Char.from_u32(34), a}, r))
    case 1n+f CBack{} <> CBack{} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{Char.from_u32(92), a}, r))
    case 1n+f CBack{} <> CSym{38n} <> rest:
      +g = f
      lex.str(g, rest, k)
    case 1n+f CBack{} <> CSym{39n} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{Char.from_u32(39), a}, r))
    case 1n+f CBack{} <> CAlpha{c} <> rest:
      +g = f
      +cs = rest
      +e = esc.take(c, cs)
      +n = esc.code(e)
      W.Bool.if(Toks(), Nat.is_gt(n, 0n), _ => lex.str(g, List.drop(&2, CC, cs, Nat.sub(String.length(e), 1n)), a => r => k(SCon{Char.from_u32(U32.from_nat(Nat.sub(n, 1n))), a}, r)), _ => Nil{})
    case 1n+f CBack{} <> CDigit{d} <> rest:
      +g = f
      lex.num(g, d, rest, n => r0 => lex.str(g, r0, a => r => k(SCon{lex.esc.code(n), a}, r)))
    case 1n+f CAlpha{c} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{c, a}, r))
    case 1n+f CDigit{d} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{cc.digit(d), a}, r))
    case 1n+f CSpace{c} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{c, a}, r))
    case 1n+f CSym{n} <> rest:
      +g = f
      lex.str(g, rest, a => r => k(SCon{Char.from_u32(U32.from_nat(n)), a}, r))
    case 1n+f _:
      Nil{}

def lex.go(fuel: Nat, cs: CCs()) -> Toks():
  match fuel cs:
    case 0n _:
      Nil{}
    case 1n+f Nil{}:
      Nil{}
    # white space at the very end is a token no reader takes: Haskell's
    # reads leaves it unread, so the text does not read whole
    case 1n+f CSpace{_} <> Nil{}:
      TSym{0n} <> Nil{}
    case 1n+f CSpace{_} <> rest:
      +g = f
      lex.go(g, rest)
    case 1n+f CDigit{d} <> rest:
      +g = f
      lex.num(g, d, rest, n => r => TNum{n} <> lex.go(g, r))
    case 1n+f CAlpha{c} <> rest:
      +g = f
      lex.id(g, rest, a => r => TKw{kw(SCon{c, a})} <> lex.go(g, r))
    case 1n+f CQuote{} <> rest:
      +g = f
      lex.str(g, rest, a => r => TStr{a} <> lex.go(g, r))
    case 1n+f CBack{} <> rest:
      +g = f
      TSym{92n} <> lex.go(g, rest)
    case 1n+f CSym{n} <> rest:
      +g = f
      TSym{n} <> lex.go(g, rest)

# the tokens of s
def lex(+s: String) -> Toks():
  lex.go(Nat.add(String.length(s), 1n), cc.all(s))

# Reading a layout (its Read: Choose, Mirror, Full, Tall's record) -----------------

def LR() -> Data:
  Maybe<&2, L.Layout>

def l.go(ok: Bool, ts: Toks(), k: Toks() -> LR()) -> LR():
  match ok:
    case True{}:
      k(ts)
    case False{}:
      None{}

def l.sym(+c: Nat, ts: Toks(), k: Toks() -> LR()) -> LR():
  match ts:
    case TSym{x} <> rest:
      l.go(Nat.is_eq(x, c), rest, k)
    case _:
      None{}

# "name =" of a record's field (name by its code)
def l.field(+code: Nat, ts: Toks(), k: Toks() -> LR()) -> LR():
  match ts:
    case TKw{x} <> TSym{61n} <> rest:
      l.go(Nat.is_eq(x, code), rest, k)
    case _:
      None{}

def l.int(ts: Toks(), k: N.Int -> Toks() -> LR()) -> LR():
  match ts:
    case TNum{n} <> rest:
      k(N.Int.of(n), rest)
    case TSym{45n} <> TNum{n} <> rest:
      k(N.Int.neg(N.Int.of(n)), rest)
    case TSym{40n} <> TSym{45n} <> TNum{n} <> TSym{41n} <> rest:
      k(N.Int.neg(N.Int.of(n)), rest)
    case _:
      None{}

def l.den(ts: Toks(), k: Nat -> Toks() -> LR()) -> LR():
  match ts:
    case TNum{1n+d} <> rest:
      k(d, rest)
    case _:
      None{}

# n % d (as a Rat: num n, den d - 1)
def l.rat(ts: Toks(), k: N.Rat -> Toks() -> LR()) -> LR():
  l.int(ts, n => t1 => l.sym(37n, t1, t2 => l.den(t2, d => t3 => k(N.Rat{n, d}, t3))))

# Tall {tallNMaster = n, tallRatioIncrement = r, tallRatio = r}
def l.tall(ts: Toks(), k: L.Layout -> Toks() -> LR()) -> LR():
  l.sym(123n, ts, t1 => l.field(39n, t1, t2 => l.int(t2, nm => t3 => l.sym(44n, t3, t4 => l.field(40n, t4, t5 => l.rat(t5, d => t6 => l.sym(44n, t6, t7 => l.field(41n, t7, t8 => l.rat(t8, f => t9 => l.sym(125n, t9, t10 => k(L.Tall{nm, d, f}, t10)))))))))))

def l.layout(fuel: Nat, ts: Toks(), k: L.Layout -> Toks() -> LR()) -> LR():
  match fuel ts:
    case 0n _:
      None{}
    case 1n+f TSym{40n} <> rest:
      +g = f
      l.layout(g, rest, x => t1 => l.sym(41n, t1, t2 => k(x, t2)))
    case 1n+f TKw{37n} <> rest:
      k(L.Full{}, rest)
    case 1n+f TKw{38n} <> rest:
      l.tall(rest, k)
    case 1n+f TKw{36n} <> rest:
      +g = f
      l.layout(g, rest, a => t1 => k(L.Mirror{a}, t1))
    case 1n+f TKw{33n} <> TKw{34n} <> rest:
      +g = f
      l.layout(g, rest, a => t1 => l.layout(g, t1, b => t2 => k(L.Choose{L.CL{}, a, b}, t2)))
    case 1n+f TKw{33n} <> TKw{35n} <> rest:
      +g = f
      l.layout(g, rest, a => t1 => l.layout(g, t1, b => t2 => k(L.Choose{L.CR{}, a, b}, t2)))
    case 1n+f _:
      None{}

def l.end(ts: Toks(), l: L.Layout) -> LR():
  match ts:
    case Nil{}:
      Some{l}
    case _:
      None{}

# whether two layouts have one shape (the same constructors, any
# parameters): a layout's Read is its type's, so the default config's,
# Choose Tall (Choose (Mirror Tall) Full), reads only that shape
def layout.shape(a: L.Layout, b: L.Layout) -> Bool:
  match a b:
    case L.Full{} L.Full{}:
      True{}
    case L.Tall{_, _, _} L.Tall{_, _, _}:
      True{}
    case L.Mirror{x} L.Mirror{y}:
      layout.shape(x, y)
    case L.Choose{_, x1, y1} L.Choose{_, x2, y2}:
      Bool.and(layout.shape(x1, x2), layout.shape(y1, y2))
    case _ _:
      False{}

def layout.read.or(m: LR(), +d: L.Layout) -> L.Layout:
  match m:
    case None{}:
      d
    case Some{+l}:
      Bool.pick(L.Layout, layout.shape(l, d), l, d)

# a layout's text, read as the default layout's type reads it (the whole
# text); the default layout if it does not read (readStateFile's
# fromMaybe layout)
def layout.read(+s: String) -> L.Layout:
  +ts = lex(s)
  layout.read.or(l.layout(Nat.add(List.length(&2, Tok, ts), 1n), ts, l => r => l.end(r, l)), C.cfg.layout())

# Reading the windowset ------------------------------------------------------------

def WR() -> Data:
  Maybe<&2, C.WindowSet()>

def w.go(ok: Bool, ts: Toks(), k: Toks() -> WR()) -> WR():
  match ok:
    case True{}:
      k(ts)
    case False{}:
      None{}

def w.sym(+c: Nat, ts: Toks(), k: Toks() -> WR()) -> WR():
  match ts:
    case TSym{x} <> rest:
      w.go(Nat.is_eq(x, c), rest, k)
    case _:
      None{}

def w.kw(+code: Nat, ts: Toks(), k: Toks() -> WR()) -> WR():
  match ts:
    case TKw{x} <> rest:
      w.go(Nat.is_eq(x, code), rest, k)
    case _:
      None{}

# "name =" of a record's field (name by its code)
def w.field(+code: Nat, ts: Toks(), k: Toks() -> WR()) -> WR():
  match ts:
    case TKw{x} <> TSym{61n} <> rest:
      w.go(Nat.is_eq(x, code), rest, k)
    case _:
      None{}

# "Name {" of a record
def w.rec(+code: Nat, ts: Toks(), k: Toks() -> WR()) -> WR():
  w.kw(code, ts, t1 => w.sym(123n, t1, k))

def w.nat(ts: Toks(), k: Nat -> Toks() -> WR()) -> WR():
  match ts:
    case TNum{n} <> rest:
      k(n, rest)
    case _:
      None{}

def w.u32(ts: Toks(), k: U32 -> Toks() -> WR()) -> WR():
  match ts:
    case TNum{n} <> rest:
      k(U32.from_nat(n), rest)
    case _:
      None{}

# a Position: n or -n, as an Int32 in a U32
def w.pos(ts: Toks(), k: U32 -> Toks() -> WR()) -> WR():
  match ts:
    case TNum{n} <> rest:
      k(U32.from_nat(n), rest)
    case TSym{45n} <> TNum{n} <> rest:
      k(U32.sub(0, U32.from_nat(n)), rest)
    case _:
      None{}

def w.str(ts: Toks(), k: String -> Toks() -> WR()) -> WR():
  match ts:
    case TStr{s} <> rest:
      k(s, rest)
    case _:
      None{}

def w.int(ts: Toks(), k: N.Int -> Toks() -> WR()) -> WR():
  match ts:
    case TNum{n} <> rest:
      k(N.Int.of(n), rest)
    case TSym{40n} <> TSym{45n} <> TNum{n} <> TSym{41n} <> rest:
      k(N.Int.neg(N.Int.of(n)), rest)
    case TSym{45n} <> TNum{n} <> rest:
      k(N.Int.neg(N.Int.of(n)), rest)
    case _:
      None{}

def w.den(ts: Toks(), k: Nat -> Toks() -> WR()) -> WR():
  match ts:
    case TNum{1n+d} <> rest:
      k(d, rest)
    case _:
      None{}

# (n % d), a RationalRect's argument
def w.rat11(ts: Toks(), k: N.Rat -> Toks() -> WR()) -> WR():
  w.sym(40n, ts, t1 => w.int(t1, n => t2 => w.sym(37n, t2, t3 => w.den(t3, d => t4 => w.sym(41n, t4, t5 => k(N.Rat{n, d}, t5))))))

# the windows of [w1,w2,...] (after "["): at the start, or after a window
def w.wins(fuel: Nat, after: Bool, acc: List<&2, U32>, ts: Toks(), k: List<&2, U32> -> Toks() -> WR()) -> WR():
  match fuel:
    case 0n:
      None{}
    case 1n+f:
      match after ts:
        case False{} TSym{93n} <> rest:
          k(List.reverse(&2, U32, acc), rest)
        case False{} TNum{n} <> rest:
          w.wins(f, True{}, U32.from_nat(n) <> acc, rest, k)
        case True{} TSym{44n} <> TNum{n} <> rest:
          w.wins(f, True{}, U32.from_nat(n) <> acc, rest, k)
        case True{} TSym{93n} <> rest:
          k(List.reverse(&2, U32, acc), rest)
        case _ _:
          None{}

def w.winlist(+fuel: Nat, ts: Toks(), k: List<&2, U32> -> Toks() -> WR()) -> WR():
  w.sym(91n, ts, t1 => w.wins(fuel, False{}, Nil{}, t1, k))

# Nothing, or Just (Stack {focus = w, up = [...], down = [...]})
def w.stack(+fuel: Nat, ts: Toks(), k: Maybe<&2, W.Stack<U32>> -> Toks() -> WR()) -> WR():
  match ts:
    case TKw{26n} <> rest:
      k(None{}, rest)
    case TKw{27n} <> rest:
      w.sym(40n, rest, t1 => w.rec(28n, t1, t2 => w.field(29n, t2, t3 => w.u32(t3, fo => t4 => w.sym(44n, t4, t5 => w.field(30n, t5, t6 => w.winlist(fuel, t6, u => t7 => w.sym(44n, t7, t8 => w.field(31n, t8, t9 => w.winlist(fuel, t9, d => t10 => w.sym(125n, t10, t11 => w.sym(41n, t11, t12 => k(Some{W.Stack{fo, u, d}}, t12)))))))))))))
    case _:
      None{}

# Workspace {tag = "t", layout = "...", stack = ...}
def w.workspace(+fuel: Nat, ts: Toks(), k: C.WindowSpace() -> Toks() -> WR()) -> WR():
  w.rec(22n, ts, t1 => w.field(23n, t1, t2 => w.str(t2, t => t3 => w.sym(44n, t3, t4 => w.field(24n, t4, t5 => w.str(t5, l => t6 => w.sym(44n, t6, t7 => w.field(25n, t7, t8 => w.stack(fuel, t8, st => t9 => w.sym(125n, t9, t10 => k(W.Workspace{t, layout.read(l), st}, t10)))))))))))

def w.rect(ts: Toks(), k: L.Rectangle -> Toks() -> WR()) -> WR():
  w.rec(17n, ts, t1 => w.field(18n, t1, t2 => w.pos(t2, x => t3 => w.sym(44n, t3, t4 => w.field(19n, t4, t5 => w.pos(t5, y => t6 => w.sym(44n, t6, t7 => w.field(20n, t7, t8 => w.u32(t8, wd => t9 => w.sym(44n, t9, t10 => w.field(21n, t10, t11 => w.u32(t11, ht => t12 => w.sym(125n, t12, t13 => k(L.Rectangle{x, y, wd, ht}, t13))))))))))))))

# Screen {workspace = ..., screen = S i, screenDetail = SD {screenRect = ...}}
def w.screen(+fuel: Nat, ts: Toks(), k: C.WScreen() -> Toks() -> WR()) -> WR():
  w.rec(10n, ts, t1 => w.field(11n, t1, t2 => w.workspace(fuel, t2, ws => t3 => w.sym(44n, t3, t4 => w.field(12n, t4, t5 => w.kw(13n, t5, t6 => w.nat(t6, i => t7 => w.sym(44n, t7, t8 => w.field(14n, t8, t9 => w.rec(15n, t9, t10 => w.field(16n, t10, t11 => w.rect(t11, r => t12 => w.sym(125n, t12, t13 => w.sym(125n, t13, t14 => k(W.Screen{ws, i, r}, t14)))))))))))))))

# a list of screens (after "["): at the start, or after a screen
def w.screens(fuel: Nat, after: Bool, acc: List<&2, C.WScreen()>, ts: Toks(), k: List<&2, C.WScreen()> -> Toks() -> WR()) -> WR():
  match fuel after ts:
    case 0n _ _:
      None{}
    case 1n+f _ TSym{93n} <> rest:
      k(List.reverse(&2, C.WScreen(), acc), rest)
    case 1n+f True{} TSym{44n} <> rest:
      +g = f
      w.screen(g, rest, x => t1 => w.screens(g, True{}, x <> acc, t1, k))
    case 1n+f False{} other:
      +g = f
      w.screen(g, other, x => t1 => w.screens(g, True{}, x <> acc, t1, k))
    case 1n+f _ _:
      None{}

def w.workspaces(fuel: Nat, after: Bool, acc: List<&2, C.WindowSpace()>, ts: Toks(), k: List<&2, C.WindowSpace()> -> Toks() -> WR()) -> WR():
  match fuel after ts:
    case 0n _ _:
      None{}
    case 1n+f _ TSym{93n} <> rest:
      k(List.reverse(&2, C.WindowSpace(), acc), rest)
    case 1n+f True{} TSym{44n} <> rest:
      +g = f
      w.workspace(g, rest, x => t1 => w.workspaces(g, True{}, x <> acc, t1, k))
    case 1n+f False{} other:
      +g = f
      w.workspace(g, other, x => t1 => w.workspaces(g, True{}, x <> acc, t1, k))
    case 1n+f _ _:
      None{}

# (w,RationalRect (a % b) (c % d) (e % f) (g % h))
def w.float(ts: Toks(), k: W.Float<U32> -> Toks() -> WR()) -> WR():
  w.sym(40n, ts, t1 => w.u32(t1, win => t2 => w.sym(44n, t2, t3 => w.kw(32n, t3, t4 => w.rat11(t4, x => t5 => w.rat11(t5, y => t6 => w.rat11(t6, wd => t7 => w.rat11(t7, ht => t8 => w.sym(41n, t8, t9 => k(W.Float{win, W.RationalRect{x, y, wd, ht}}, t9))))))))))

def w.floats(fuel: Nat, after: Bool, acc: List<&2, W.Float<U32>>, ts: Toks(), k: List<&2, W.Float<U32>> -> Toks() -> WR()) -> WR():
  match fuel:
    case 0n:
      None{}
    case 1n+f:
      match after ts:
        case _ TSym{93n} <> rest:
          k(List.reverse(&2, W.Float<U32>, acc), rest)
        case True{} TSym{44n} <> rest:
          w.float(rest, x => t1 => w.floats(f, True{}, x <> acc, t1, k))
        case False{} other:
          w.float(other, x => t1 => w.floats(f, True{}, x <> acc, t1, k))
        case _ _:
          None{}

# sfExt's [(name,text),...]: read and dropped (xmonad-bend keeps no
# extensible state)
def w.ext(fuel: Nat, after: Bool, ts: Toks(), k: Toks() -> WR()) -> WR():
  match fuel:
    case 0n:
      None{}
    case 1n+f:
      match after ts:
        case _ TSym{93n} <> rest:
          k(rest)
        case True{} TSym{44n} <> TSym{40n} <> TStr{_} <> TSym{44n} <> TStr{_} <> TSym{41n} <> rest:
          w.ext(f, True{}, rest, k)
        case False{} TSym{40n} <> TStr{_} <> TSym{44n} <> TStr{_} <> TSym{41n} <> rest:
          w.ext(f, True{}, rest, k)
        case _ _:
          None{}

def w.end(ts: Toks(), s: C.WindowSet()) -> WR():
  match ts:
    case Nil{}:
      Some{s}
    case _:
      None{}

# StateFile {sfWins = StackSet {current = ..., visible = [...], hidden =
# [...], floating = fromList [...]}, sfExt = [...]}, and nothing after
def w.stateFile(+fuel: Nat, ts: Toks()) -> WR():
  w.rec(1n, ts, t1 => w.field(2n, t1, t2 => w.rec(3n, t2, t3 => w.field(4n, t3, t4 => w.screen(fuel, t4, c => t5 => w.sym(44n, t5, t6 => w.field(5n, t6, t7 => w.sym(91n, t7, t8 => w.screens(fuel, False{}, Nil{}, t8, v => t9 => w.sym(44n, t9, t10 => w.field(6n, t10, t11 => w.sym(91n, t11, t12 => w.workspaces(fuel, False{}, Nil{}, t12, h => t13 => w.sym(44n, t13, t14 => w.field(7n, t14, t15 => w.kw(8n, t15, t16 => w.sym(91n, t16, t17 => w.floats(fuel, False{}, Nil{}, t17, fl => t18 => w.sym(125n, t18, t19 => w.sym(44n, t19, t20 => w.field(9n, t20, t21 => w.sym(91n, t21, t22 => w.ext(fuel, False{}, t22, t23 => w.sym(125n, t23, t24 => w.end(t24, W.StackSet{c, v, h, fl})))))))))))))))))))))))))

# readStateFile: the windowset of a state file's text, its layouts read
# (the default for one that does not read), then W.ensureTags with the
# configuration's workspaces; None if the text does not read as a whole
def read.ensure(m: WR()) -> WR():
  match m:
    case None{}:
      None{}
    case Some{s}:
      Some{W.ensureTags(~String, ~String.eq, L.Layout, U32, Nat, L.Rectangle, C.cfg.layout(), C.cfg.workspaces(), s)}

def read(+text: String) -> WR():
  +ts = lex(text)
  read.ensure(w.stateFile(Nat.add(List.length(&2, Tok, ts), 1n), ts))
