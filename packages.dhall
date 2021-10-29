let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.14.4-20211005/packages.dhall
        sha256:2ec351f17be14b3f6421fbba36f4f01d1681e5c7f46e0c981465c4cf222de5be

let overrides = {=}

let additions =
      { dissect =
        { dependencies =
          [ "bifunctors"
          , "either"
          , "fixed-points"
          , "functors"
          , "lists"
          , "partial"
          , "prelude"
          , "safe-coerce"
          , "tailrec"
          , "tuples"
          , "typelevel-prelude"
          , "unsafe-coerce"
          ]
        , repo = "https://github.com/PureFunctor/purescript-dissect.git"
        , version = "v0.1.0"
        }
      , benchotron =
        { dependencies =
          [ "arrays"
          , "console"
          , "datetime"
          , "effect"
          , "exceptions"
          , "exists"
          , "foldable-traversable"
          , "identity"
          , "lcg"
          , "node-fs"
          , "node-readline"
          , "now"
          , "numbers"
          , "profunctor"
          , "quickcheck"
          , "strings"
          , "transformers"
          ]
        , repo = "https://github.com/hdgarrood/purescript-benchotron.git"
        , version = "e64664de1fa0843ca78949f36b31b176fa6b0f84"
        }
      }

in  upstream // overrides // additions
