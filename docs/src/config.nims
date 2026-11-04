# nimib and its dependencies from deps.sh (ZOGYN_DOCS_DEPS, default ./deps), plus zogyn itself.
import std/os
let deps = getEnv("ZOGYN_DOCS_DEPS", thisDir() / "deps")
for d in ["nimib", "fusion", "markdown", "parsetoml", "jsony"]:
  switch("path", deps / d / "src")
switch("path", thisDir() / ".." / ".." / "src")
switch("hints", "off")
