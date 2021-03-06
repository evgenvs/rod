# Package
version       = "0.1.0"
author        = "Anonymous"
description   = "Graphics engine"
license       = "MIT"

bin           = @["rod/tools/rodasset/rodasset"]

# Dependencies
requires "nimx"
requires "https://github.com/SSPKrolik/nimasset"
requires "variant"
requires "native_dialogs"
requires "https://github.com/yglukhov/imgtools"
requires "cligen"
requires "https://github.com/yglukhov/zip" # Until https://github.com/nim-lang/zip/pull/21 is merged
requires "tempfile"
requires "https://github.com/yglukhov/threadpools"
