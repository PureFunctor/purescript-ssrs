module Benchmark.Main where

import Prelude

import Benchmark.Common (listOf, polyListOf)
import Benchmark.Folding.SSRS as FoldingSSRS
import Benchmark.Folding.SSRSPoly as FoldingSSRSPoly
import Benchmark.Folding.Matryoshka as FoldingMatryoshka
import Benchotron.Core (Benchmark, benchFn, mkBenchmark)
import Benchotron.UI.Console (runSuite)
import Data.Array ((..))
import Effect (Effect)
import Test.QuickCheck.Arbitrary (arbitrary)

foldingList ∷ Benchmark
foldingList = mkBenchmark
  { slug: "foldingList"
  , title: "Integer summation"
  , sizes: (1 .. 25) <#> (_ * 1000)
  , sizeInterpretation: "List length"
  , inputsPerSize: 100
  , gen: \n → listOf n arbitrary
  , functions:
      [ benchFn "ssrs" FoldingSSRS.sigma
      , benchFn "matryoshka" FoldingMatryoshka.sigma
      ]
  }

foldingListPoly ∷ Benchmark
foldingListPoly = mkBenchmark
  { slug: "foldingListPoly"
  , title: "Integer summation"
  , sizes: (1 .. 25) <#> (_ * 1000)
  , sizeInterpretation: "List length"
  , inputsPerSize: 100
  , gen: \n → polyListOf n arbitrary
  , functions:
      [ benchFn "ssrs" FoldingSSRSPoly.sigma
      ]
  }

main ∷ Effect Unit
main = runSuite [ foldingList, foldingListPoly ]
