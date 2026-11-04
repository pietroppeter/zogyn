# Package

version       = "0.1.0"
author        = "Pietro Peterlongo"
description   = "Declarative dragging for Nim: list the states a drag can reach, the dragging falls out"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 2.0.0"
# zogyn/nbstage imports nimib, which is not required: install it if you use that module.

task test, "Run the engine tests (native) and check the JS runtime compiles":
  exec "nim r --hints:off tests/test_zogyn.nim"
  exec "nim js --hints:off -o:tests/stage_check.js src/zogyn/stage.nim"
  rmFile "tests/stage_check.js"

task docs, "Build docs/index.html (fetches nimib into docs/src/deps first)":
  exec "sh docs/src/deps.sh"
  withDir "docs/src":
    exec "nim c -r -d:release index.nim"
