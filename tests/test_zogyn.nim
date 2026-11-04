import std/[unittest, math, strutils]
import zogyn

proc slot(i: int): Vec = vec(50 + 100 * i.float, 50)
proc renderRow(xs: seq[string]): seq[Item] =
  for i, x in xs: result.add Item(key: x, pos: slot(i), svg: x)
proc rowSpec(xs: seq[string], key: string): Behavior[seq[string]] =
  closest(xs.reorderings(key))

suite "engine":
  let word = @["Z", "O", "G", "Y", "N"]

  test "locate is speculative rendering":
    check renderRow.locate(word, "G") == vec(250, 50)
    check renderRow.locate(word, "Q").isNaN

  test "moveTo and reorderings":
    check word.moveTo("N", 0) == @["N", "Z", "O", "G", "Y"]
    check word.reorderings("Z").len == 5

  test "closest picks the nearest landing":
    let p = rowSpec(word, "Z")(renderRow, "Z")
    check p.lands.len == 5
    let c = p.pick(vec(240, 70))
    check c.ok
    check c.state == @["O", "G", "Z", "Y", "N"]
    check abs(c.dist - hypot(10.0, 20.0)) < 1e-9

  test "drag simulates a whole gesture":
    let path = [vec(60, 50), vec(200, 40), vec(430, 55)]
    check drag(rowSpec, renderRow, word, "Z", path) == @["O", "G", "Y", "N", "Z"]

  test "nil spec means not draggable":
    let none: Spec[seq[string]] = proc (s: seq[string], k: string): Behavior[seq[string]] = nil
    check dragTo(none, renderRow, word, "Z", vec(400, 50)) == word

  test "within declines far drops, orElse falls back":
    let b = closest(word.reorderings("Z")).within(20)
    let p = b(renderRow, "Z")
    check p.pick(vec(250, 60)).ok
    check not p.pick(vec(200, 50)).ok
    let fb = closest(word.reorderings("Z")).within(20).orElse(closest(@[word]))
    check fb(renderRow, "Z").pick(vec(200, 50)).state == word

  test "onlyIf turns rules into fewer states":
    let notLast = proc (s: seq[string]): bool = s[^1] != "Z"
    let p = closest(word.reorderings("Z")).onlyIf(notLast)(renderRow, "Z")
    check not p.pick(vec(450, 50)).ok
    let q = closestAllowed(word.reorderings("Z"), notLast)(renderRow, "Z")
    check q.lands.len == 4
    check q.pick(vec(450, 50)).state == @["O", "G", "Y", "Z", "N"]

  test "vary finds a continuous parameter":
    let r: Render[float] = proc (t: float): seq[Item] = @[Item(key: "k", pos: vec(t * 10, 0))]
    let p = vary(proc (t: float): float = t, 0, 10)(r, "k")
    let c = p.pick(vec(37.3, 5))
    check abs(c.state - 3.73) < 1e-6

  test "free follows the pointer":
    let r: Render[Vec] = proc (v: Vec): seq[Item] = @[Item(key: "p", pos: v)]
    let c = free(proc (p: Vec): Vec = p)(r, "p").pick(vec(3, 4))
    check c.state == vec(3, 4) and c.dist == 0

  test "sticky keeps its pick near the midpoint":
    let p = rowSpec(word, "Z").sticky(30)(renderRow, "Z")
    check p.pick(vec(140, 50)).state[1] == "Z"   # nearer slot 1
    check p.pick(vec(160, 50)).state[1] == "Z"   # slot 2 is only 20 nearer: stay
    check p.pick(vec(240, 50)).state[2] == "Z"   # now clearly slot 2

  test "snapshot draws a static svg":
    let svg = snapshot(renderRow, word, 500, 100)
    check svg.count("<g ") == 5
