## "graph paper" theme for the zogyn docs: a drafting table for things you drag.
## Light: cream grid paper, navy ink, Nim yellow highlighter, tomato for the machinery.
## Dark: the same drawing as a blueprint.
const pageStyle* = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,800&family=Atkinson+Hyperlegible:ital,wght@0,400;0,700;1,400&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
:root{
  --paper:#f7f4ea; --grid:#dfe7ee; --grid2:#c9d6e2; --card:#fffdf7; --ink:#14213d; --muted:#5d6b82; --line:#d9dfe6;
  --nim:#ffe953; --hot:#ef4f3a; --blue:#2563eb; --mint:#2fb79a; --codebg:#fffdf7; --codeink:#1f2a44;
  --out:#14213d; --outink:#eef2f8; --chip:#e9eef6;
  --t1:#ffe953; --t2:#8fd3f0; --t3:#ffa69e; --t4:#b8f2c8; --t5:#cdb4f6; --t6:#ffc982;
}
@media (prefers-color-scheme: dark){ :root:not([data-theme="light"]){
  --paper:#0f2342; --grid:#173159; --grid2:#1d3a68; --card:#132b50; --ink:#e8eefb; --muted:#9fb1cf; --line:#284777;
  --codebg:#0c1d38; --codeink:#dbe5f7; --out:#07152b; --outink:#dbe5f7; --chip:#1d3a68;
}}
:root[data-theme="dark"]{
  --paper:#0f2342; --grid:#173159; --grid2:#1d3a68; --card:#132b50; --ink:#e8eefb; --muted:#9fb1cf; --line:#284777;
  --codebg:#0c1d38; --codeink:#dbe5f7; --out:#07152b; --outink:#dbe5f7; --chip:#1d3a68;
}
*{box-sizing:border-box}
code,pre,samp{font-variant-ligatures:none}
p code,li code,td code{overflow-wrap:anywhere}
[hidden]{display:none!important}
:root{padding:env(safe-area-inset-top,0) env(safe-area-inset-right,0) env(safe-area-inset-bottom,0) env(safe-area-inset-left,0)}
html{background:var(--paper)}
body{margin:0 auto;max-width:780px;padding:0 16px 60px;color:var(--ink);
  font:17.5px/1.62 "Atkinson Hyperlegible",system-ui,sans-serif;
  background-color:var(--paper);
  background-image:linear-gradient(var(--grid2) 1px,transparent 1px),linear-gradient(90deg,var(--grid2) 1px,transparent 1px),
    linear-gradient(var(--grid) 1px,transparent 1px),linear-gradient(90deg,var(--grid) 1px,transparent 1px);
  background-size:120px 120px,120px 120px,24px 24px,24px 24px;background-attachment:fixed}
header,footer .nb-box{display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap;
  font:13px "JetBrains Mono",monospace;color:var(--muted);padding:14px 0}
header{border-bottom:2px solid var(--ink)} footer .nb-box{border-top:2px solid var(--ink);margin-top:44px}
header a, footer a{color:var(--muted)}
header .logo{font:800 18px "Bricolage Grotesque",sans-serif;color:var(--ink);letter-spacing:-.02em}
header .logo i{font-style:normal;background:var(--nim);color:#14213d;border:2px solid var(--ink);border-radius:6px;padding:0 6px;margin-right:6px}
h1,h2,h3{font-family:"Bricolage Grotesque",sans-serif;line-height:1.05;letter-spacing:-.025em}
h1{font-size:clamp(40px,9vw,72px);font-weight:800;margin:34px 0 8px}
h1 em{font-style:normal;background:linear-gradient(transparent 55%,var(--nim) 55%);color:inherit;padding:0 .06em}
@media (prefers-color-scheme: dark){ :root:not([data-theme="light"]) h1 em{background:none;color:var(--nim)} }
:root[data-theme="dark"] h1 em{background:none;color:var(--nim)}
h2{font-size:32px;font-weight:800;margin:56px 0 10px}
h2 .num{font:600 12.5px "JetBrains Mono",monospace;color:var(--hot);display:block;margin-bottom:8px;letter-spacing:.12em}
h3{font-size:22px;font-weight:800;margin:32px 0 6px}
a{color:var(--blue);text-decoration-thickness:1.5px;text-underline-offset:3px}
@media (prefers-color-scheme: dark){ :root:not([data-theme="light"]) a{color:#8fb8ff} }
:root[data-theme="dark"] a{color:#8fb8ff}
p code, li code, td code{font:14.5px "JetBrains Mono",monospace;background:var(--chip);padding:1px 5px;border-radius:5px}
.lede{font-size:21px;line-height:1.5;max-width:40em}
.kicker{font:600 13px "JetBrains Mono",monospace;letter-spacing:.12em;color:var(--hot);margin-top:34px}
blockquote{margin:18px 0;padding:8px 16px;border-left:5px solid var(--nim);background:var(--card);border-radius:0 10px 10px 0}
pre{margin:14px 0;overflow-x:auto;border-radius:12px}
pre code, pre code.hljs{display:block;padding:14px 16px;font:13.4px/1.55 "JetBrains Mono",monospace;background:var(--codebg);
  border:2px solid var(--ink);border-radius:12px;color:var(--codeink)}
pre.nb-output, pre samp{display:block;padding:12px 16px;font:13px/1.5 "JetBrains Mono",monospace;background:var(--out);
  color:var(--outink);border-radius:12px;white-space:pre;overflow-x:auto}
.hljs-keyword{color:#c2410c;font-weight:600}.hljs-type,.hljs-built_in{color:#2563eb}.hljs-string{color:#15803d}
.hljs-number,.hljs-literal{color:#a21caf}.hljs-comment{color:#7c8aa3;font-style:italic}.hljs-meta{color:#0e7490}
@media (prefers-color-scheme: dark){ :root:not([data-theme="light"]) .hljs-keyword{color:#ffb38a}
  :root:not([data-theme="light"]) .hljs-type,:root:not([data-theme="light"]) .hljs-built_in{color:#8fb8ff}
  :root:not([data-theme="light"]) .hljs-string{color:#9be3a8} :root:not([data-theme="light"]) .hljs-number{color:#f0abfc} }
table{border-collapse:collapse;width:100%;margin:14px 0;font-size:15.5px;background:var(--card);border:2px solid var(--ink)}
th,td{text-align:left;padding:7px 10px;border-bottom:1px solid var(--line);vertical-align:top}
th{font:600 12px "JetBrains Mono",monospace;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)}
details{margin:14px 0;border:2px dashed var(--grid2);border-radius:12px;padding:4px 12px;background:var(--card)}
details summary{cursor:pointer;font:13px "JetBrains Mono",monospace;color:var(--muted);padding:6px 0}
/* stages (overrides of zogyn/nbstage defaults) */
body .zogyn-stage{--zg-ink:var(--ink);--zg-card:var(--card);--zg-muted:var(--muted);--zg-hot:var(--hot);
  border-radius:18px;box-shadow:6px 6px 0 var(--ink)}
.zogyn-stage svg text{font-family:"Bricolage Grotesque",sans-serif}
.zogyn-stage svg .mono{font-family:"JetBrains Mono",monospace}
.zogyn-stage .ink{fill:var(--ink)} .zogyn-stage .inks{stroke:var(--ink)} .zogyn-stage .muted{fill:var(--muted)}
.zogyn-stage .faint{stroke:var(--line)} .zogyn-stage .cellbg{fill:var(--paper)}
.zogyn-snapshot .ink{fill:#14213d}
.controls{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0;align-items:center}
.controls button{font:600 13px "JetBrains Mono",monospace;border:2px solid var(--ink);background:var(--card);color:var(--ink);
  border-radius:999px;padding:6px 14px;cursor:pointer;box-shadow:2px 2px 0 var(--ink)}
.controls button.on{background:var(--nim);color:#14213d}
.controls button:active{transform:translate(2px,2px);box-shadow:none}
.status{font:13px "JetBrains Mono",monospace;color:var(--muted);margin:4px 2px 0;min-height:1.6em}
.filmstrip{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:10px;margin:14px 0}
.filmstrip figure{margin:0;background:var(--card);border:2px solid var(--ink);border-radius:12px;padding:6px;text-align:center}
.filmstrip figure svg{background:#fffdf7;border-radius:8px}
.filmstrip figcaption{font:12px "JetBrains Mono",monospace;color:var(--muted);margin-top:4px}
#source{display:none}
footer button{font:600 12px "JetBrains Mono",monospace;border:2px solid var(--ink);background:var(--card);color:var(--ink);border-radius:999px;padding:4px 12px;cursor:pointer}
footer hr{display:none}
</style>
"""
