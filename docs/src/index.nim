import std/[json, os, strformat]
import nimib
import zogyn, zogyn/nbstage
import style

nbInit
# write the page next to src/, wherever the build is run from
nb.doc.filename = currentSourcePath().parentDir.parentDir / "index.html"
nb.doc.context["title"] = %"zogyn: declarative dragging for Nim"
nb.doc.context["stylesheet"] = %pageStyle
nb.doc.context["highlight"] = %""
func pageHeader(blk: JsonNode, nb: Nb): string =
  """<header><span class="logo"><i>z</i>zogyn</span><span>declarative dragging for Nim · <a href="https://github.com/pietroppeter/zogyn">github</a></span></header>"""
nb.backend.partials["header"] = pageHeader
nbZogynStyle()

nbRawHtml: """
<div class="kicker">A NIM LIBRARY · WORKS IN NIMIB</div>
<h1>Don't write drag handlers. <em>Declare</em> where things can go.</h1>
<p class="lede">zogyn is <a href="https://declarative-dragging.github.io/">Declarative Dragging</a> for Nim.
For the thing you grab, you list the model states the drag can reach. zogyn renders each one
speculatively, shows the one that lands your element closest to the pointer, and commits it on release.
Snapping, reordering, rules and sliders all come from that one move.</p>
"""

nbCodeAnd(nbJsFromCode):
  import std/[strformat, strutils]
  import zogyn
  const hues = ["#ffe953", "#8fd3f0", "#ffa69e", "#b8f2c8", "#cdb4f6", "#ffc982"]

  proc tile(letter, hue: string, size = 76.0): string =
    let h = size / 2
    &"""<rect x="{-h}" y="{-h}" width="{size}" height="{size}" rx="{size / 5}" fill="{hue}" stroke="#14213d" stroke-width="3"/>""" &
    &"""<text y="{size * 0.17}" text-anchor="middle" font-size="{size * 0.5}" font-weight="800" fill="#14213d">{letter}</text>"""

  proc renderWord(word: seq[string]): seq[Item] =
    for i, letter in word:
      result.add Item(key: letter, pos: vec(70 + i.float * 115, 70),
                      svg: tile(letter, hues["ZOGYN".find(letter)]))

  proc wordSpec(word: seq[string], key: string): Behavior[seq[string]] =
    closest(word.reorderings(key))

nbStage("hero"):
  import zogyn/stage
  let hero = mount("hero", 600, 140, @["G", "Y", "N", "O", "Z"], renderWord, wordSpec, ghosts = true)

nbText: """
Grab a tile and spell **ZOGYN**. The coral dots are the *machinery*: one speculative landing spot per reachable state.
Nobody wrote "shift the other tiles right". The interaction above is the block you just read, and the
spec is one line: `closest(word.reorderings(key))`.

The idea, and the name of its operators, come from **Declarative Dragging** by Joshua Horowitz, Andrew Blinn and
Jeffrey Heer ([UIST 2026, Best Paper](https://uist.acm.org/2026/awards/)), whose library is
[Dragology](https://github.com/declarative-dragging/dragology) (TypeScript, React). zogyn grew out of
[a nimib notebook port](https://pietroppeter.github.io/claude-artifacts/declarative-dragging-nim/) and packages it
as a library: a **pure engine** that runs on every backend, a small **browser runtime** for `nim js`, and **nimib helpers**.
"""

nbRawHtml: """<h2><span class="num">01 · INSTALL</span>Three modules</h2>"""

nbText: """
```sh
nimble install https://github.com/pietroppeter/zogyn
```

| module | backend | what it gives you |
|---|---|---|
| `zogyn` | any | `Item`, `Render[S]`, `Spec[S]`, `Behavior[S]`, the behaviours, `drag` simulation, `snapshot` |
| `zogyn/stage` | JS | `mount` an SVG stage in an element; `setState`, `onCommit`, `onMove`, `locked` |
| `zogyn/nbstage` | native | `nbStage`, `nbZogynStyle`, `nbSnapshot` for nimib documents |

The whole contract is three things you write:

1. a **model** `S`: any Nim type with `==` (a `seq`, an `object`, a `float`);
2. a **render** `proc (s: S): seq[Item]`: keyed items, each with a position and some SVG drawn around (0, 0);
3. a **spec** `proc (s: S, key: string): Behavior[S]`: for the grabbed key, the states it may reach (`nil` = not draggable).
"""

nbRawHtml: """<h2><span class="num">02 · THE ENGINE</span>Behaviours are values</h2>"""

nbText: """
A `Behavior[S]` is built from a few constructors and combined with operators. Because they're just values you can
pick one at runtime, store it, or build it from a rule.

| behaviour | meaning |
|---|---|
| `closest(states)` | snap to whichever state lands the element nearest the pointer |
| `vary(t => f(t), lo, hi)` | continuous parameter: the element slides along the path `f` traces |
| `free(p => f(p))` | the state follows the held position directly |
| `b.within(r)` | decline unless the landing spot is within `r` px |
| `a.orElse(b)` | try `a`; if it declines, use `b` |
| `b.sticky(m)` | keep the current pick until another lands `m` px closer (no flicker) |
| `b.onlyIf(rule)` / `closestAllowed(states, rule)` | rules become fewer states, not validation code |

Since the engine has no DOM, the same spec can be **driven natively**. Here's that while nimib builds this page:
grab `Z` and release it where the second slot is.
"""

nbCode:
  let start = @["G", "Y", "N", "O", "Z"]
  let picker = wordSpec(start, "Z")(renderWord, "Z")
  for i, land in picker.lands:
    let st = start.reorderings("Z")[i]
    echo &"state {i}: {st.join}  Z lands at ({int(land.x)}, {int(land.y)})"
  let after = dragTo(wordSpec, renderWord, start, "Z", vec(190, 80))
  echo "released at (190, 80) → ", after

nbText: "`snapshot` draws any state as a static SVG at build time, so tests, docs and no-JS fallbacks reuse the render:"

nbCode:
  var strip = """<div class="filmstrip">"""
  var s = start
  strip.add &"""<figure>{snapshot(renderWord, s, 600, 140)}<figcaption>start: {s.join}</figcaption></figure>"""
  for (key, x) in [("Z", 70.0), ("O", 185.0)]:
    s = dragTo(wordSpec, renderWord, s, key, vec(x, 70))
    strip.add &"""<figure>{snapshot(renderWord, s, 600, 140)}<figcaption>drag {key} → {s.join}</figcaption></figure>"""
  strip.add "</div>"
nbRawHtml: strip

nbRawHtml: """<h2><span class="num">03 · SOURCES</span>A stack of copies for every letter</h2>"""

nbText: """
A palette you drag *from* needs no "spawn" feature. Give every copy its own key (`Z1` … `Z4`) and let the render
decide where unplaced copies sit: fanned in a stack beside the board. Dragging the top copy reaches "that copy in each
empty cell"; dragging a placed copy can also reach "back to the stack". The stack effect, the return animation and
the hand-off between copies all fall out of keyed rendering.

Toggle **rules** to feed the same states through `closestAllowed` with a Latin-square rule: illegal cells simply stop
being reachable, so their dots vanish. (This is the pattern behind the draggable Wordoku in
[parloku](https://github.com/pietroppeter/parloku).)
"""

nbCodeAnd(nbJsFromCode):
  const
    symbols = ["Z", "O", "G", "N"]
    copies = 4
    cell = 72.0

  type Board = object
    cells: array[16, string]     ## copy key in each cell, "" when empty

  proc symbolOf(copy: string): string = copy[0 .. 0]
  proc cellPos(i: int): Vec = vec(24 + cell / 2 + float(i mod 4) * cell, 24 + cell / 2 + float(i div 4) * cell)
  proc unplaced(b: Board, sym: string): seq[string] =
    for c in 1 .. copies:
      let k = sym & $c
      if k notin b.cells: result.add k

  proc renderBoard(b: Board): seq[Item] =
    for i, k in b.cells:
      if k.len > 0:
        result.add Item(key: k, pos: cellPos(i), svg: tile(symbolOf(k), hues[symbols.find(symbolOf(k))], 60))
    for si, sym in symbols:
      for depth, k in b.unplaced(sym):        # a fanned deck: later copies on top
        result.add Item(key: k, pos: vec(400 + depth.float * 7, 60 + si.float * 72 - depth.float * 3),
                        svg: tile(sym, hues[si], 60))

  proc place(b: Board, k: string, i: int): Board =
    result = b
    let j = b.cells.find(k)
    if j >= 0: result.cells[j] = ""
    result.cells[i] = k

  proc unplace(b: Board, k: string): Board =
    result = b
    result.cells[b.cells.find(k)] = ""

  proc legal(b: Board): bool =
    ## no symbol twice in a row, column or 2×2 box
    for i in 0 ..< 16:
      for j in i + 1 ..< 16:
        let (a, c) = (b.cells[i], b.cells[j])
        if a.len > 0 and c.len > 0 and symbolOf(a) == symbolOf(c):
          let sameBox = (i div 8 == j div 8) and ((i mod 4) div 2 == (j mod 4) div 2)
          if i div 4 == j div 4 or i mod 4 == j mod 4 or sameBox: return false
    true

  var rules = false
  proc boardSpec(b: Board, k: string): Behavior[Board] =
    let placed = k in b.cells
    if not placed and b.unplaced(symbolOf(k))[^1] != k: return nil   # only the top of a stack
    var states = @[b]
    if placed: states.add b.unplace(k)
    for i in 0 ..< 16:
      if b.cells[i].len == 0: states.add b.place(k, i)
    if rules: closestAllowed(states, legal) else: closest(states)

nbStage("board"):
  import std/dom
  proc boardBackdrop(b: Board): string =
    for i in 0 ..< 16:
      let p = cellPos(i)
      result.add &"""<rect class="cellbg faint" x="{p.x - cell / 2 + 3}" y="{p.y - cell / 2 + 3}" width="{cell - 6}" height="{cell - 6}" rx="10" stroke-width="2"/>"""
    result.add """<path class="inks" d="M168,24 v288 M24,168 h288" stroke-width="3" fill="none"/>"""
    result.add """<rect class="inks" x="24" y="24" width="288" height="288" rx="6" stroke-width="3" fill="none"/>"""
    var full = true
    for k in b.cells:
      if k.len == 0: full = false
    let msg = if full and legal(b): "solved ✦ every row, column and box" else: "drag from the stacks"
    result.add &"""<text class="muted mono" x="24" y="340" font-size="14">{msg}</text>"""
  let board = mount("board", 560, 360, Board(), renderBoard, boardSpec, boardBackdrop, ghosts = true)
  let rulesBtn = document.getElementById("rules")
  rulesBtn.addEventListener("click", proc (ev: Event) =
    rules = not rules
    rulesBtn.classList.toggle("on")
    board.refresh())
  document.getElementById("clear").addEventListener("click", proc (ev: Event) = board.setState(Board()))

nbRawHtml: """<div class="controls"><button id="rules">rules: Latin square</button><button id="clear">clear</button></div>"""

nbRawHtml: """<h2><span class="num">04 · COMPOSITION</span>Free, magnetic, and along a curve</h2>"""

nbText: """
Three behaviours on one model, a cubic Bézier. The four handles use
`closest(gridPoints).within(14).orElse(free(...))`: they move freely but snap to the grid when they pass close to
it, like a drawing app with magnetic guides. The pink bead uses `vary` on `t`, so it can only slide **along the curve**,
whatever shape the curve has right now. Nobody projected a point onto a Bézier; `vary` searched it.
"""

nbCodeAnd(nbJsFromCode):
  type Curve = object
    pts: array[4, Vec]
    t: float

  proc bezier(c: Curve, t: float): Vec =
    let (a, b, d, e) = (c.pts[0], c.pts[1], c.pts[2], c.pts[3])
    let u = 1 - t
    a * (u * u * u) + b * (3 * u * u * t) + d * (3 * u * t * t) + e * (t * t * t)

  proc renderCurve(c: Curve): seq[Item] =
    for i, p in c.pts:
      result.add Item(key: &"p{i}", pos: p, svg:
        &"""<circle r="13" fill="{hues[i + 1]}" stroke="#14213d" stroke-width="3"/>""")
    result.add Item(key: "bead", pos: c.bezier(c.t), svg:
      """<circle r="11" fill="#ef4f3a" stroke="#14213d" stroke-width="3"/>""")

  proc withPoint(c: Curve, i: int, p: Vec): Curve =
    result = c
    result.pts[i] = p

  proc curveSpec(c: Curve, key: string): Behavior[Curve] =
    if key == "bead":
      return vary(proc (t: float): Curve = Curve(pts: c.pts, t: t), 0, 1, samples = 80)
    let i = parseInt(key[1 .. ^1])
    var grid: seq[Curve]
    for gx in 1 .. 14:
      for gy in 1 .. 6:
        grid.add c.withPoint(i, vec(gx.float * 40, gy.float * 40))
    closest(grid).within(14).orElse(free(proc (p: Vec): Curve = c.withPoint(i, p)))

nbStage("curve"):
  proc curveBackdrop(c: Curve): string =
    for gx in 1 .. 14:
      for gy in 1 .. 6:
        result.add &"""<circle class="muted" cx="{gx * 40}" cy="{gy * 40}" r="1.6" opacity=".6"/>"""
    let p = c.pts
    result.add &"""<path class="inks" d="M{p[0].x},{p[0].y} L{p[1].x},{p[1].y} M{p[2].x},{p[2].y} L{p[3].x},{p[3].y}" stroke-width="1.5" stroke-dasharray="5 5" fill="none" opacity=".6"/>"""
    result.add &"""<path class="inks" d="M{p[0].x},{p[0].y} C{p[1].x},{p[1].y} {p[2].x},{p[2].y} {p[3].x},{p[3].y}" stroke-width="5" fill="none" stroke-linecap="round"/>"""
    result.add &"""<text class="muted mono" x="20" y="272" font-size="14">t = {c.t:.3f}</text>"""
  let curve0 = Curve(pts: [vec(80, 200), vec(160, 40), vec(400, 240), vec(520, 80)], t: 0.5)
  discard mount("curve", 600, 280, curve0, renderCurve, curveSpec, curveBackdrop, ghosts = true)

nbRawHtml: """<h2><span class="num">05 · IN YOUR NIMIB DOCUMENT</span>Two templates</h2>"""

nbText: """
Write the model in `nbCodeAnd(nbJsFromCode)` so it runs natively (for printed outputs and snapshots) **and**
ships to the page. Then `nbStage(id)` emits a container and compiles its body to JavaScript, where you `mount` it.

```nim
import nimib, zogyn/nbstage
nbInit
nbZogynStyle()                       # default stage look; restyle with CSS vars

nbCodeAnd(nbJsFromCode):
  import zogyn
  proc renderWord(word: seq[string]): seq[Item] =
    for i, letter in word:
      result.add Item(key: letter, pos: vec(70 + i.float * 115, 70), svg: tileSvg(letter))
  proc wordSpec(word: seq[string], key: string): Behavior[seq[string]] =
    closest(word.reorderings(key))

nbStage("hero"):
  import zogyn/stage
  let hero = mount("hero", 600, 140, @["G", "Y", "N", "O", "Z"], renderWord, wordSpec)
  hero.onCommit = proc (before, after: seq[string]) =
    if after == @["Z", "O", "G", "Y", "N"]: echo "spelled!"
nbSave
```

Two practical notes:

- `nbJsFromCode` compiles a temporary file **in the current directory** with `nim js`, so `zogyn` must be importable
  from there: installed with nimble, or on the path via a `config.nims` next to your document (that's how this page is built).
- nimib ships `nbJsFromCode` bodies through the AST's `repr`, which drops the parentheses of an inline `if` used as an
  argument (`f(if a: b else: c)`). Bind it with `let` first.

Outside nimib the runtime is plain Nim: `nim js` a file that imports `zogyn/stage`, and call `mount` with the id of an
element on your page. `stage.locked = true` freezes input (an opponent's turn), `setState` drives it from code
(reset, undo, a computer move), and `onCommit(before, after)` is where game logic hooks in.
"""

nbRawHtml: """<h2><span class="num">06 · CREDITS</span>Read the real thing</h2>"""

nbText: """
- Joshua Horowitz, Andrew Blinn, Jeffrey Heer. [*Declarative Dragging*](https://andrewblinn.com/papers/D2.pdf), UIST 2026, Best Paper.
  Project page with interactive figures: [declarative-dragging.github.io](https://declarative-dragging.github.io/).
- [Dragology](https://github.com/declarative-dragging/dragology), the authors' TypeScript library. zogyn covers its core
  (`closest`, `vary`, `within`, `orElse`, floating drags, speculative rendering) and adds `free`, `sticky`, `onlyIf` and
  native `drag` simulation. Chained drags and the paper's smarter continuous solver are not here (yet).
- The notebook this grew from: [Declarative Dragging, in Nim](https://pietroppeter.github.io/claude-artifacts/declarative-dragging-nim/).

Built with [nimib](https://github.com/pietroppeter/nimib). Hit *show source* below for the whole document.
"""

nbSave
