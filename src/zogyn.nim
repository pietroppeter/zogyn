## zogyn: declarative dragging for Nim
## ====================================
##
## You don't write drag handlers. You describe, for the element being grabbed,
## which model states the drag may reach. zogyn renders each candidate state
## *speculatively* (a plain function call), finds where the grabbed element would
## land in it, and while the element floats under the pointer it shows the state
## whose landing spot is closest. On release, that state is committed.
##
## The idea is from *Declarative Dragging* by Joshua Horowitz, Andrew Blinn and
## Jeffrey Heer (UIST 2026), whose TypeScript library is Dragology. This module is
## the pure engine: no DOM, so it runs natively (tests, build-time rendering) and
## in the browser through `nim js`. The browser runtime is `zogyn/stage`.

import std/[math, sequtils]

type
  Vec* = object
    x*, y*: float

  Item* = object             ## one keyed element of a rendered view
    key*: string             ## identity across states (what your eye tracks)
    pos*: Vec                ## where it sits in this state
    svg*: string             ## what it looks like, drawn around (0, 0)

  Render*[S] = proc (s: S): seq[Item]
    ## a view: a pure function from model to keyed, positioned items

  Choice*[S] = object
    ok*: bool                ## false when the behaviour declines (e.g. out of `within` range)
    state*: S
    land*: Vec               ## where the dragged element lands in `state`
    dist*: float             ## distance from the pointer to `land`

  Picker*[S] = object        ## a behaviour, instantiated at drag start
    lands*: seq[Vec]         ## speculative landing spots, for display
    pick*: proc (p: Vec): Choice[S]

  Behavior*[S] = proc (render: Render[S], key: string): Picker[S]
    ## what a drag may do; build them with `closest`, `vary`, `free`
    ## and combine them with `within`, `orElse`, `sticky`, `onlyIf`

  Spec*[S] = proc (s: S, key: string): Behavior[S]
    ## the whole interaction: for a state and a grabbed key, its behaviour
    ## (nil means the element can't be dragged)

# ---------------------------------------------------------------- vectors

func vec*(x, y: float): Vec = Vec(x: x, y: y)
func `+`*(a, b: Vec): Vec = vec(a.x + b.x, a.y + b.y)
func `-`*(a, b: Vec): Vec = vec(a.x - b.x, a.y - b.y)
func `*`*(a: Vec, k: float): Vec = vec(a.x * k, a.y * k)
func norm*(a: Vec): float = hypot(a.x, a.y)
func dist*(a, b: Vec): float = norm(a - b)
func lerp*(a, b: Vec, t: float): Vec = a + (b - a) * t
func isNaN*(a: Vec): bool = a.x != a.x or a.y != a.y
const nowhere* = Vec(x: NaN, y: NaN)

# ---------------------------------------------------------------- speculative rendering

proc locate*[S](render: Render[S], s: S, key: string): Vec =
  ## speculative rendering: draw `s` without painting it,
  ## and report where the element `key` would land (`nowhere` if absent)
  for it in render(s):
    if it.key == key: return it.pos
  nowhere

proc landDist(land, p: Vec): float =
  if land.isNaN: Inf else: dist(land, p)

# ---------------------------------------------------------------- behaviours

proc closest*[S](states: seq[S]): Behavior[S] =
  ## discrete: snap to the state that lands the element nearest the pointer.
  ## States where the element is absent are never picked.
  result = proc (render: Render[S], key: string): Picker[S] =
    var lands: seq[Vec]
    for s in states: lands.add render.locate(s, key)
    result.lands = lands
    result.pick = proc (p: Vec): Choice[S] =
      result.dist = Inf
      for i, s in states:
        let d = landDist(lands[i], p)
        if d < result.dist:
          result = Choice[S](ok: true, state: s, land: lands[i], dist: d)

proc vary*[S](f: proc (t: float): S, lo, hi: float, samples = 64): Behavior[S] =
  ## continuous: the state is `f(t)` for some `t` in `lo .. hi`. Samples the path
  ## the element traces, then refines between the nearest samples (ternary search).
  result = proc (render: Render[S], key: string): Picker[S] =
    var ts: seq[float]
    var lands: seq[Vec]
    for i in 0 .. samples:
      let t = lo + (hi - lo) * i.float / samples.float
      ts.add t
      lands.add render.locate(f(t), key)
    result.lands = lands
    result.pick = proc (p: Vec): Choice[S] =
      var best = 0
      for i in 1 .. samples:
        if landDist(lands[i], p) < landDist(lands[best], p): best = i
      var a = ts[max(best - 1, 0)]
      var b = ts[min(best + 1, samples)]
      let distAt = proc (t: float): float = landDist(render.locate(f(t), key), p)
      for _ in 1 .. 30:
        let m1 = a + (b - a) / 3
        let m2 = b - (b - a) / 3
        if distAt(m1) < distAt(m2): b = m2 else: a = m1
      let s = f((a + b) / 2)
      let land = render.locate(s, key)
      Choice[S](ok: not land.isNaN, state: s, land: land, dist: landDist(land, p))

proc free*[S](f: proc (p: Vec): S): Behavior[S] =
  ## free: the state is a function of where the element is held,
  ## e.g. `free(p => s.withPoint(key, p))`. The element goes where you put it.
  result = proc (render: Render[S], key: string): Picker[S] =
    result.pick = proc (p: Vec): Choice[S] =
      let s = f(p)
      let land = render.locate(s, key)
      Choice[S](ok: not land.isNaN, state: s, land: land, dist: landDist(land, p))

proc within*[S](b: Behavior[S], radius: float): Behavior[S] =
  ## snapping: decline unless the landing spot is closer than `radius`
  result = proc (render: Render[S], key: string): Picker[S] =
    let inner = b(render, key)
    result.lands = inner.lands
    result.pick = proc (p: Vec): Choice[S] =
      result = inner.pick(p)
      if result.dist > radius: result.ok = false

proc orElse*[S](a, b: Behavior[S]): Behavior[S] =
  ## fallback: try `a`, and if it declines use `b`
  result = proc (render: Render[S], key: string): Picker[S] =
    let pa = a(render, key)
    let pb = b(render, key)
    result.lands = pa.lands & pb.lands
    result.pick = proc (p: Vec): Choice[S] =
      result = pa.pick(p)
      if not result.ok: result = pb.pick(p)

proc sticky*[S](b: Behavior[S], margin: float): Behavior[S] =
  ## hysteresis: keep the current pick until another lands at least `margin`
  ## closer. Stops flicker when the pointer sits halfway between two states.
  result = proc (render: Render[S], key: string): Picker[S] =
    let inner = b(render, key)
    var last: Choice[S]
    result.lands = inner.lands
    result.pick = proc (p: Vec): Choice[S] =
      var c = inner.pick(p)
      if last.ok and c.ok and c.state != last.state:
        let held = landDist(render.locate(last.state, key), p)
        if held < c.dist + margin:
          c = Choice[S](ok: true, state: last.state, land: last.land, dist: held)
      last = c
      c

proc onlyIf*[S](b: Behavior[S], allowed: proc (s: S): bool): Behavior[S] =
  ## legality: only offer the states `allowed` accepts. Rules of a game
  ## become fewer reachable states, not validation code.
  result = proc (render: Render[S], key: string): Picker[S] =
    let inner = b(render, key)
    result.lands = inner.lands
    result.pick = proc (p: Vec): Choice[S] =
      result = inner.pick(p)
      if result.ok and not allowed(result.state): result.ok = false

proc closestAllowed*[S](states: seq[S], allowed: proc (s: S): bool): Behavior[S] =
  ## `closest` over just the states `allowed` accepts (the landing spots of
  ## forbidden states are not even shown)
  closest(states.filterIt(allowed(it)))

# ---------------------------------------------------------------- simulation

proc drag*[S](spec: Spec[S], render: Render[S], s: S, key: string,
              path: openArray[Vec]): S =
  ## drive a whole drag without a screen: grab `key` in `s`, move the
  ## held element along `path`, release. Returns the committed state.
  ## Handy for tests and for drawing at build time.
  result = s
  let b = spec(s, key)
  if b.isNil or path.len == 0: return
  let picker = b(render, key)
  var c: Choice[S]
  for p in path: c = picker.pick(p)
  if c.ok: result = c.state

proc dragTo*[S](spec: Spec[S], render: Render[S], s: S, key: string, p: Vec): S =
  ## a drag released at `p`
  drag(spec, render, s, key, [p])

proc moveTo*[T](xs: seq[T], x: T, i: int): seq[T] =
  ## list surgery: `x` taken out and reinserted at index `i`
  ## (the model behind every reorderable list)
  result = xs
  result.delete(xs.find(x))
  result.insert(x, i)

proc reorderings*[T](xs: seq[T], x: T): seq[seq[T]] =
  ## every placement of `x` in `xs`: `closest(xs.reorderings(x))` is a sortable list
  for i in 0 ..< xs.len: result.add xs.moveTo(x, i)

# ---------------------------------------------------------------- static output

proc snapshot*[S](render: Render[S], s: S, w, h: float,
                  backdrop: proc (s: S): string = nil, class = "zogyn-snapshot"): string =
  ## a static `<svg>` of state `s`, for build-time figures (nimib `nbRawHtml`)
  ## or a no-JavaScript fallback
  result = "<svg class=\"" & class & "\" viewBox=\"0 0 " & $w & " " & $h & "\">"
  if not backdrop.isNil: result.add backdrop(s)
  for it in render(s):
    result.add "<g transform=\"translate(" & $it.pos.x & "," & $it.pos.y & ")\">" & it.svg & "</g>"
  result.add "</svg>"
