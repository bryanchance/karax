# Virtual DOM implementation

from dom import Event

type
  VNodeKind* {.pure.} = enum
    text,
    anchor,
    tdiv,
    table, tr, td, th, thead, tbody,
    link, span, label, br, select, option,
    fieldset, input

const
  toTag*: array[VNodeKind, cstring] = [
    cstring"#text", "A", "DIV", "TABLE", "TR", "TD", "TH", "THEAD", "TBODY", "LINK",
    "SPAN", "LABEL", "BR", "SELECT", "OPTION", "FIELDSET", "INPUT"
  ]

type
  EventKind* {.pure.} = enum
    onclick, onkeyup, onkeydown, onkeypressed, onblur, onchange, onscroll

const
  toEventName*: array[EventKind, cstring] = [
    cstring"click", "keyup", "keydown", "keypressed", "blur", "change", "scroll"
  ]

type
  EventHandler* = proc (ev: Event; target: VNode) {.closure.}
  VNode* = ref object
    kind*: VNodeKind
    id*, class*, text*: cstring
    kids: seq[VNode]
    # even index: key, odd index: value; done this way for memory efficiency:
    attrs: seq[cstring]
    events*: seq[(EventKind, EventHandler)]

proc value*(n: VNode): cstring = n.text
proc `value=`*(n: VNode; v: cstring) = n.text = v

proc setAttr*(n: VNode; key: cstring; val: cstring = "") =
  if n.attrs.isNil:
    n.attrs = @[key, val]
  else:
    for i in countup(0, n.attrs.len-2, 2):
      if n.attrs[i] == key:
        n.attrs[i+1] = val
        return
    n.attrs.add key
    n.attrs.add val

proc getAttr*(n: VNode; key: cstring): cstring =
  for i in countup(0, n.attrs.len-2, 2):
    if n.attrs[i] == key: return n.attrs[i+1]

proc len*(x: VNode): int = x.kids.len
proc `[]`*(x: VNode; idx: int): VNode = x.kids[idx]
proc add*(parent, kid: VNode) = parent.kids.add kid
proc newVNode*(kind: VNodeKind): VNode = VNode(kind: kind)

proc tree*(kind: VNodeKind; kids: varargs[VNode]): VNode =
  result = newVNode(kind)
  for k in kids: result.add k

proc tree*(kind: VNodeKind; attrs: openarray[(cstring, cstring)];
           kids: varargs[VNode]): VNode =
  result = tree(kind, kids)
  for a in attrs: result.setAttr(a[0], a[1])

proc text*(s: string): VNode = VNode(kind: VNodeKind.text, text: cstring(s))
proc text*(s: cstring): VNode = VNode(kind: VNodeKind.text, text: s)

iterator items*(n: VNode): VNode =
  for i in 0..<n.kids.len: yield n.kids[i]

iterator attrs*(n: VNode): (cstring, cstring) =
  for i in countup(0, n.attrs.len-2, 2):
    yield (n.attrs[i], n.attrs[i+1])

proc addEventListener*(n: VNode; event: EventKind; handler: EventHandler) =
  n.events.add((event, handler))