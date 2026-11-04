## zogyn/stage: the browser runtime (JS backend only)
## ==================================================
##
## Mounts an SVG stage in an element, turns pointer events into `pick` calls,
## renders the picked state for everything except the held element (which floats
## under the pointer) and commits on release. One `<g>` per key is kept across
## renders, so a CSS transition on `.item` slides everything to its new place.
##
## CSS hooks: `.item`, `.item.grab` (draggable), `.item.lifted` (held),
## `.bg` (backdrop layer), `.ghosts .land/.best/.tether/.path` (the machinery),
## `.ghost-toggle` (the "show machinery" checkbox).

when not defined(js):
  {.error: "zogyn/stage needs the JS backend: compile with `nim js`".}

import std/[dom, strformat, tables, sequtils]
import ../zogyn

proc svgNode(tag: cstring): Element {.importjs: "document.createElementNS('http://www.w3.org/2000/svg', #)".}
proc capture(e: Element, ev: Event) {.importjs: "#.setPointerCapture(#.pointerId)".}
proc keyAt(ev: Event): cstring {.importjs: "(#.target.closest('[data-key]')?.dataset.key ?? null)".}
proc setStyle(e: Element, k, v: cstring) {.importjs: "#.style.setProperty(#, #)".}
proc checked(e: Element): bool {.importjs: "#.checked".}
proc clientXY(ev: Event): Vec {.importjs: "(e => ({x: e.clientX, y: e.clientY}))(#)".}
proc rectOf(e: Element): (float, float, float, float) {.importjs:
  "(() => { const r = #.getBoundingClientRect(); return {Field0: r.left, Field1: r.top, Field2: r.width, Field3: r.height}; })()".}

type Stage*[S] = ref object
  state*: S                  ## the committed model
  render*: Render[S]
  spec*: Spec[S]
  backdrop*: proc (s: S): string   ## optional SVG drawn under the items
  svg*, bg*, ghosts*, fg*, host*: Element
  nodes: Table[string, Element]
  looks: Table[string, string]
  w*, h*: float
  dragKey*: string           ## key being held, "" when idle
  grab, at*: Vec             ## pointer offset at grab; where the held item floats
  picker*: Picker[S]
  choice*: Choice[S]
  showGhosts*: bool
  locked*: bool              ## when true nothing can be grabbed (e.g. opponent's turn)
  onMove*: proc ()           ## after every render (drag start, move, release, setState)
  onCommit*: proc (before, after: S)  ## after a release that changed the state

proc tr*(p: Vec): cstring = cstring(&"translate({p.x:.2f}px, {p.y:.2f}px)")

proc shown*[S](st: Stage[S]): S =
  ## the state on screen: the picked one while dragging, else the committed one
  if st.dragKey.len > 0 and st.choice.ok: st.choice.state else: st.state

proc drawGhosts*[S](st: Stage[S]) =
  var g = ""
  if st.dragKey.len > 0 and st.showGhosts:
    let many = st.picker.lands.len > 40
    for l in st.picker.lands:
      if not l.isNaN:
        let (cls, r) = if many: ("path", 2.6) else: ("land", 7.0)
        g.add &"""<circle class="{cls}" cx="{l.x}" cy="{l.y}" r="{r}"/>"""
    if st.choice.ok:
      let c = st.choice.land
      g.add &"""<line class="tether" x1="{st.at.x}" y1="{st.at.y}" x2="{c.x}" y2="{c.y}"/>"""
      g.add &"""<circle class="best" cx="{c.x}" cy="{c.y}" r="13"/>"""
  st.ghosts.innerHTML = cstring(g)

proc draw*[S](st: Stage[S], s: S) =
  ## render `s` (keeping the held element under the pointer)
  if not st.backdrop.isNil: st.bg.innerHTML = cstring(st.backdrop(s))
  var seen: seq[string]
  for it in st.render(s):
    seen.add it.key
    let held = it.key == st.dragKey
    var n = st.nodes.getOrDefault(it.key)
    if n.isNil:
      n = svgNode("g")
      n.setAttribute("data-key", cstring(it.key))
      n.setStyle("transform", tr(it.pos))
      st.fg.appendChild(n)
      st.nodes[it.key] = n
    if st.looks.getOrDefault(it.key) != it.svg:
      n.innerHTML = cstring(it.svg)
      st.looks[it.key] = it.svg
    let canGrab = not st.locked and st.dragKey.len == 0 and not st.spec(s, it.key).isNil
    let grab = if canGrab: " grab" else: ""
    let lifted = if held: " lifted" else: ""
    let pos = if held: st.at else: it.pos
    n.setAttribute("class", cstring("item" & grab & lifted))
    n.setStyle("transform", tr(pos))
  for k in toSeq(st.nodes.keys):
    if k notin seen:
      st.fg.removeChild(st.nodes[k])
      st.nodes.del k
      st.looks.del k
  st.drawGhosts()

proc changed[S](st: Stage[S]) =
  if not st.onMove.isNil: st.onMove()

proc move*[S](st: Stage[S], p: Vec) =
  ## the held element is at `p` (pointer position minus grab offset)
  st.at = p - st.grab
  st.choice = st.picker.pick(st.at)
  st.draw(st.shown)
  st.changed()

proc start*[S](st: Stage[S], key: string, p: Vec): bool {.discardable.} =
  ## grab `key` with the pointer at `p`; false if it isn't draggable
  if st.locked: return false
  let behavior = st.spec(st.state, key)
  if behavior.isNil: return false
  st.dragKey = key
  st.grab = p - st.render.locate(st.state, key)
  st.picker = behavior(st.render, key)   # speculative renders happen here
  st.fg.appendChild(st.nodes[key])       # float above the others
  st.move(p)
  true

proc finish*[S](st: Stage[S]) =
  ## release: commit the picked state, the held element glides home
  if st.dragKey.len == 0: return
  let before = st.state
  if st.choice.ok: st.state = st.choice.state
  st.dragKey = ""
  st.draw(st.state)
  st.changed()
  if st.choice.ok and st.state != before and not st.onCommit.isNil:
    st.onCommit(before, st.state)

proc setState*[S](st: Stage[S], s: S) =
  ## replace the model from outside (reset buttons, computer moves...)
  st.state = s
  st.draw(s)
  st.changed()

proc refresh*[S](st: Stage[S]) = st.draw(st.shown)

proc mount*[S](id: string, w, h: float, init: S, render: Render[S], spec: Spec[S],
               backdrop: proc (s: S): string = nil, ghosts = false,
               toggle = true): Stage[S] =
  ## mount a stage of `w`×`h` user units in the element with id `id`
  let host = document.getElementById(cstring(id))
  let chk = if ghosts: "checked" else: ""
  var html = &"""<svg class="d2" viewBox="0 0 {w} {h}"><g class="bg"></g>""" &
    """<g class="fg"></g><g class="ghosts"></g></svg>"""
  if toggle:
    html.add &"""<label class="ghost-toggle"><input type="checkbox" {chk}> show machinery</label>"""
  host.innerHTML = cstring(html)
  let st = Stage[S](state: init, render: render, spec: spec, backdrop: backdrop,
                    w: w, h: h, showGhosts: ghosts, host: host)
  st.svg = host.querySelector("svg")
  st.bg = host.querySelector(".bg")
  st.ghosts = host.querySelector(".ghosts")
  st.fg = host.querySelector(".fg")
  let toLocal = proc (ev: Event): Vec =
    let (l, t, rw, rh) = rectOf(st.svg)
    let c = clientXY(ev)
    vec((c.x - l) * w / rw, (c.y - t) * h / rh)
  st.svg.addEventListener("pointerdown", proc (ev: Event) =
    let k = keyAt(ev)
    if k.isNil or st.dragKey.len > 0: return
    if st.start($k, toLocal(ev)):
      ev.preventDefault()
      capture(st.svg, ev))
  st.svg.addEventListener("pointermove", proc (ev: Event) =
    if st.dragKey.len > 0: st.move(toLocal(ev)))
  st.svg.addEventListener("pointerup", proc (ev: Event) = st.finish())
  st.svg.addEventListener("pointercancel", proc (ev: Event) = st.finish())
  if toggle:
    let box = host.querySelector(".ghost-toggle input")
    box.addEventListener("change", proc (ev: Event) =
      st.showGhosts = box.checked
      st.drawGhosts())
  st.draw(init)
  st
