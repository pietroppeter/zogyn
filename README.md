# zogyn

**Declarative dragging for Nim.** You don't write drag handlers: for the element being grabbed you list the model
states the drag can reach. zogyn renders each one *speculatively*, shows the state that lands the element closest to
the pointer, and commits it on release. Reordering, snapping, sources, game rules and sliders all come from that.

Docs and live demos (a nimib document): [`docs/index.html`](docs/index.html), served at
https://pietroppeter.github.io/zogyn/ once GitHub Pages is enabled for `main` / `docs`.

The idea is from *Declarative Dragging* by Joshua Horowitz, Andrew Blinn and Jeffrey Heer
([UIST 2026, Best Paper](https://uist.acm.org/2026/awards/)), whose library is
[Dragology](https://github.com/declarative-dragging/dragology) (TypeScript, React). zogyn packages the
[Nim notebook port](https://pietroppeter.github.io/claude-artifacts/declarative-dragging-nim/) as a library.

## Modules

| module | backend | contents |
|---|---|---|
| `zogyn` | any | `Item`, `Render[S]`, `Spec[S]`, `Behavior[S]`; `closest`, `vary`, `free`, `within`, `orElse`, `sticky`, `onlyIf`, `closestAllowed`; `drag`/`dragTo` simulation; `snapshot` (static SVG); `moveTo`, `reorderings` |
| `zogyn/stage` | JS | `mount(id, w, h, init, render, spec, backdrop, ghosts)` an SVG stage; `setState`, `refresh`, `locked`, `onMove`, `onCommit(before, after)` |
| `zogyn/nbstage` | native, nimib | `nbStage(id): body` (container + JS that mounts it), `nbZogynStyle()`, `nbSnapshot` |

## Example

```nim
import zogyn

proc renderWord(word: seq[string]): seq[Item] =
  for i, letter in word:
    result.add Item(key: letter, pos: vec(70 + i.float * 115, 70), svg: tileSvg(letter))

proc wordSpec(word: seq[string], key: string): Behavior[seq[string]] =
  closest(word.reorderings(key))       # a sortable list: that's the whole interaction

# natively, e.g. in a test:
assert dragTo(wordSpec, renderWord, @["O", "Z"], "Z", vec(70, 70)) == @["Z", "O"]

# in the browser (nim js):
import zogyn/stage
let st = mount("word", 600, 140, @["G", "Y", "N", "O", "Z"], renderWord, wordSpec)
st.onCommit = proc (before, after: seq[string]) = echo after
```

In a nimib document put the model in `nbCodeAnd(nbJsFromCode)` and mount it with `nbStage`; see
[`docs/src/index.nim`](docs/src/index.nim). `nbJsFromCode` compiles with `nim js` from the current directory, so
zogyn must be importable there (nimble install, or a `config.nims` adding it to the path).

## Develop

```sh
nimble test    # engine tests (native) + JS compile check of the runtime
nimble docs    # fetch nimib at pinned commits and rebuild docs/index.html
```

The docs build needs libpcre (PCRE1) for nimib's `std/re`.
