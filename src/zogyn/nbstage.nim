## zogyn/nbstage: drag stages in nimib documents
## ===========================================
##
## Import next to `nimib` (zogyn does not depend on nimib; this module is only
## compiled if you import it). Typical document:
##
## ```nim
## import nimib, zogyn/nbstage
## nbInit
## nbZogynStyle()                      # default look for stages (optional)
##
## nbCodeAnd(nbJsFromCode):            # the model: runs natively *and* in the page
##   import zogyn
##   proc renderRow(xs: seq[string]): seq[Item] = ...
##   proc rowSpec(xs: seq[string], key: string): Behavior[seq[string]] =
##     closest(xs.reorderings(key))
##
## nbStage("row"):                     # a <div id="row"> plus the JS that mounts it
##   import zogyn/stage
##   discard mount("row", 500, 100, @["Z", "O", "G", "Y", "N"], renderRow, rowSpec)
## nbSave
## ```
##
## `nbJsFromCode` compiles a temporary file in the current directory with
## `nim js`, so zogyn must be importable from there: installed with nimble,
## or put on the path by a `config.nims` next to the document.

import nimib

const zogynCss* = """
<style>
.zogyn-stage{--zg-ink:#1d1b16;--zg-card:#fffdf8;--zg-muted:#6b6457;--zg-hot:#e4572e;
  position:relative;margin:18px 0 6px;background:var(--zg-card);border:2px solid var(--zg-ink);
  border-radius:16px;box-shadow:5px 5px 0 var(--zg-ink);padding:6px}
.zogyn-stage svg.d2{display:block;overflow:visible;width:100%;height:auto;touch-action:none;
  user-select:none;-webkit-user-select:none}
.zogyn-stage .item{transition:transform .32s cubic-bezier(.2,.9,.25,1)}
.zogyn-stage .item.grab{cursor:grab}
.zogyn-stage .item.lifted{transition:none;cursor:grabbing;filter:drop-shadow(0 9px 8px rgba(0,0,0,.28))}
.zogyn-stage .ghosts{pointer-events:none}
.zogyn-stage .ghosts .land{fill:var(--zg-hot);opacity:.55}
.zogyn-stage .ghosts .best{fill:none;stroke:var(--zg-hot);stroke-width:3}
.zogyn-stage .ghosts .tether{stroke:var(--zg-hot);stroke-width:2;stroke-dasharray:4 4}
.zogyn-stage .ghosts .path{fill:var(--zg-hot);opacity:.35}
.zogyn-stage .ghost-toggle{position:absolute;right:12px;bottom:8px;font:12px ui-monospace,monospace;
  color:var(--zg-muted);cursor:pointer;user-select:none}
.zogyn-stage .ghost-toggle input{accent-color:var(--zg-hot);vertical-align:-2px}
.zogyn-snapshot{display:block;width:100%;height:auto}
</style>
"""

func stageHtml*(id: string, class = "zogyn-stage"): string =
  ## the container a stage mounts into
  "<div class=\"" & class & "\" id=\"" & id & "\"></div>"

template nbZogynStyle*() =
  ## add the default stage CSS to the document (once, anywhere)
  nbRawHtml(zogynCss)

template nbStage*(id: string, body: untyped) =
  ## a stage container with id `id`, followed by `body` compiled to JS
  ## (where you `mount(id, ...)`)
  nbRawHtml(stageHtml(id))
  nbJsFromCode(body)

template nbSnapshot*(render, s, w, h: untyped) =
  ## a static picture of state `s`, drawn at build time
  nbRawHtml(snapshot(render, s, w, h))
